cluster = require \cluster
num-cpus = require \os .cpus().length


if cluster.is-master

  work-items-done = {}

  send-work = (id) ->
    console.log "Master sending work to worker #id"
    cluster.workers[id].send {type: \work, data: {time-to-wait: Math.random()}}

  item-completed = (id) ->
    work-items-done[id] ?= 0
    work-items-done[id]++
    console.log "Another item done by worker #id! His total: #{work-items-done[id]} Overall total: #{total()}"

  total = ->
    t = 0
    for id, n of work-items-done
      t = t + n
    t

  stop-all-workers = ->
    for id, worker of cluster.workers
      worker.send {type: \stop}

  cluster.on \online, (worker) ->
    console.log "#{worker.id} is online"
    send-work(worker.id)

  cluster.on \exit, ({id}) ->
    console.log "worker #id just snuffed it... he completed #{work-items-done[id]} tasks"

  # create some threads
  for i from 1 to num-cpus
    cluster.fork()

  for id, worker of cluster.workers
    let id=id, worker=worker
      console.log "listening to worker #id"
      worker.on \message, (msg) ->
        console.log "Recieved message '#msg' from worker #id"
        if total() >= 20
          item-completed(id)
        else if total() < 20
          item-completed(id)
          send-work id

else if cluster.is-worker
  reply = ->
    console.log "Worker #{cluster.worker.id} finished... requesting more work"
    process.send "I'm done... can I have some more please?"

  handle-message = ({type, data}) ->
    | type is \stop =>
      console.log "GOODBYE CRUEL WORLD!!!!!"
      cluster.worker.destroy()
    | type is \work =>
      console.log "worker #{cluster.worker.id} handling message"
      setTimeout(reply, data.time-to-wait * 10000)

  process.on \message, handle-message



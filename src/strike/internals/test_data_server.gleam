import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import youid/uuid

pub type Message(element) {
  Get(reply_with: Subject(Result(element, Nil)))
}

pub fn new() {
  actor.start(None, fn(message, state) {
    case message {
      Get(client) -> {
        case state {
          Some(data) -> {
            process.send(client, Ok(data))
            actor.continue(state)
          }
          None -> {
            let data = test_data()
            process.send(client, Ok(data))
            actor.continue(Some(data))
          }
        }
      }
    }
  })
}

pub fn get(actor) {
  let assert Ok(test_data) = process.call(actor, Get, 100)
  test_data
}

pub fn test_data() {
  list.range(1, 1000)
  |> list.map(fn(_) {
    let id = uuid.v4_string()
    let name = uuid.v4_string()
    #(id, name)
  })
  // #(
  //   "8d0ec5b9-e69c-4fb8-98ec-151ac96eb5f5",
  //   "a77f1d97-9fca-4116-8d62-38bdb8c52ae5",
  // )
  // [
  //   #("id", "8d0ec5b9-e69c-4fb8-98ec-151ac96eb5f5"),
  //   #("name", "a77f1d97-9fca-4116-8d62-38bdb8c52ae5"),
  // ]
}

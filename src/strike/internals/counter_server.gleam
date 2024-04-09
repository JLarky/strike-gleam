import gleam/otp/actor
import gleam/erlang/process.{type Subject}

pub type Message(element) {
  Get(reply_with: Subject(Result(element, Nil)))
  Inc(reply_with: Subject(Result(element, Nil)))
}

pub fn new() {
  actor.start(0, fn(message, state) {
    case message {
      Get(client) -> {
        process.send(client, Ok(state))
        actor.continue(state)
      }
      Inc(client) -> {
        process.send(client, Ok(state))
        actor.continue(state + 1)
      }
    }
  })
}

pub fn get(actor) {
  let assert Ok(counter) = process.call(actor, Get, 100)
  counter
}

pub fn inc(actor) {
  let assert Ok(counter) = process.call(actor, Inc, 100)
  counter
}

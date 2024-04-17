import gleam/erlang/process.{type Subject}
import gleam/otp/actor

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
        let state = state + 1
        process.send(client, Ok(state))
        actor.continue(state)
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

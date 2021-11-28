import { Controller } from "stimulus"

export default class extends Controller {
  override initialize() {
    console.log("test#initialize")
  }

  override connect() {
    console.log("test#connect")
  }

  override disconnect() {
    console.log("test#disconnect")
  }
}

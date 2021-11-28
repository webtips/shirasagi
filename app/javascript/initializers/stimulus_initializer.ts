import Initializer from "../ss/initializer"
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

export default class StimulusInitializer extends Initializer {
  override initialize(): Promise<void> {
    return Promise.resolve()
  }

  override afterInitialize(): Promise<void> {
    const application = new Application()
    const ret = application.start()
    const context = require.context("../controllers", true, /(\.js|\.ts)$/)
    application.load(definitionsFromContext(context))

    return ret
  }
}

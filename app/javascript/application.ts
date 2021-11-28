import Initializer from "./ss/initializer"
import i18next from 'i18next'

Initializer.load(require.context("./initializers", true, /(\.js|\.ts)$/))
const promise = Initializer.initialize()
promise.then(() => console.log(i18next.t("hello")))

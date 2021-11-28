import Initializer from "./ss/initializer"
Initializer.load(require.context("./initializers", true, /(\.js|\.ts)$/))
const promise = Initializer.initialize()
promise.then(() => console.log("hello"))

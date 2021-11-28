type Constructor = new() => Initializer

export default abstract class Initializer {
  private static initialized = false;
  private static initializers: Constructor[] = []

  static initialize(): Promise<void> {
    if (Initializer.initialized) {
      return Promise.resolve();
    }
    Initializer.initialized = true;

    const instances: Initializer[] = [];
    Initializer.initializers.forEach(constructor => {
      instances.push(new constructor());
    })

    const promises: Promise<void>[] = [];
    instances.forEach(instance => {
      promises.push(instance.initialize());
    })

    return new Promise((resolve, reject) => {
      Promise.all<void>(promises)
        .then(() => {
          promises.length = 0;
          instances.forEach(instance => {
            promises.push(instance.afterInitialize());
          })
          return Promise.all<void>(promises)
        })
        .then(() => resolve())
        .catch(err => reject(err))
    });
  }

  static register<T extends Initializer>(constructor: { new(): T }) {
    Initializer.initializers.push(constructor)
  }

  static load(context) {
    context.keys().forEach(key => {
      const module = context(key)
      const constructor = module.default as any
      if (typeof constructor == "function") {
        Initializer.register(constructor)
      } else {
        console.info(`${key}: there isn't constructor`)
      }
    })
  }

  initialize(): Promise<void> {
    return Promise.resolve()
  }

  afterInitialize(): Promise<void> {
    return Promise.resolve()
  }
}

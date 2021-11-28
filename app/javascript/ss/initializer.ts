type Constructor = new() => Initializer

export default abstract class Initializer {
  private static initialized = false;
  private static initializers: Constructor[] = []

  static initialize(): Promise<void> {
    if (Initializer.initialized) {
      return new Promise((resolve) => resolve());
    }
    Initializer.initialized = true;

    const promises: Promise<void>[] = [];
    Initializer.initializers.forEach((constructor) => {
      const initializer: Initializer = new constructor();
      promises.push(initializer.initialize());
    })

    return new Promise((resolve, reject) => {
      Promise.all<void>(promises)
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
      }
    })
  }

  abstract initialize(): Promise<void>;
}

import Initializer from "../ss/initializer"

export default class Dom extends Initializer {
  override initialize(): Promise<void> {
    return new Promise(resolve => window.addEventListener('DOMContentLoaded', () => resolve()))
  }
}

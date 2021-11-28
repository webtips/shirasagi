import Initializer from "../ss/initializer"
import i18next from 'i18next'
import LanguageDetector from 'i18next-browser-languagedetector';
import en from "../locales/en.json"
import ja from "../locales/ja.json"

export default class I18nextInitializer extends Initializer {
  override initialize(): Promise<void> {
    return new Promise((resolve, reject) => {
      i18next.use(LanguageDetector).init({
        detection: {
          order: ['htmlTag', 'cookie', 'localStorage', 'sessionStorage', 'navigator']
        },
        resources: {
          ja, en
        },
        fallbackLng: ['en', 'ja']
      }, (err, t) => {
        if (err) {
          reject(err)
        } else {
          resolve()
        }
      })
    })
  }
}

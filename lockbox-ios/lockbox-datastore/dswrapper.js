
async function swiftOpen(cfg) {
  return (new SwiftInteropDataStore(cfg)).prepare();
}

class SwiftInteropDataStore extends DataStoreModule.DataStore {
  constructor(cfg) {
    super(cfg)
  }

  async prepare() {
    return super.prepare().then(function(result) {
        try {
          webkit.messageHandlers.OpenComplete.postMessage("done")
        } catch (err) {
          console.log("callback function not available")
        }

        return result
      }
    );
  }

  async initialize(opts) {
    return super.initialize(opts).then( function(result) {
      try {
        webkit.messageHandlers.InitializeComplete.postMessage("done")
      } catch (err) {
        console.log("callback function not available")
      }

      return result
    }
    );
  }

  async lock() {
    return super.lock().then( function(result) {
      console.log("locked!!")
        try {
          webkit.messageHandlers.LockComplete.postMessage("lock success")
        } catch (err) {
          console.log("callback function not available")
        }

        return result
      }
    )
  }

  async unlock(scopedKey) {
      return super.unlock(scopedKey).then( function(result) {
        try {
          webkit.messageHandlers.UnlockComplete.postMessage("unlock success")
        } catch (err) {
          console.log("callback function not available")
        }
      }
    )
  }

  async list() {
    return super.list().then( function(entryList) {
      try {
        webkit.messageHandlers.ListComplete.postMessage(Array.from(entryList))
      } catch (err) {
        console.log("callback function not available")
      }
    })
  }

  async touch(item) {
    return super.touch(item).then( function(updatedItem) {
      try {
        webkit.messageHandlers.UpdateComplete.postMessage(updatedItem)
      } catch (err) {
        console.log("callback function not available")
      }
    })
  }
}

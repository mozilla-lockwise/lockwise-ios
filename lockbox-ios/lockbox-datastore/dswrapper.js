
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
      console.log("successful initialization")
      try {
        console.log("successful initialization")
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

  async unlock(pwd) {
      return super.unlock(pwd).then( () => {
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

  async get(id) {
    return super.get(id).then( function(entry) {
      try {
        webkit.messageHandlers.GetComplete.postMessage(entry)
      } catch (err) {
        console.log("callback function not available")
      }
    })
  }

  async add(item) {
    return super.add(item).then( function(addedItem) {
      console.log("adding completed successfully!")
      try {
        webkit.messageHandlers.AddComplete.postMessage(addedItem)
      } catch (err) {
        console.log("callback function not available")
      }
    })
  }

  async update(item) {
    return super.update(item).then( function(updatedItem) {
      try {
        webkit.messageHandlers.UpdateComplete.postMessage(updatedItem)
      } catch (err){
        console.log("callback function not available")
      }
    })
  }

  async remove(id) {
    return super.remove(id).then( () => {
        try {
          webkit.messageHandlers.DeleteComplete.postMessage("delete completed")
        } catch (err) {
          console.log("callback function not available")
        }
      }
    )
  }
}

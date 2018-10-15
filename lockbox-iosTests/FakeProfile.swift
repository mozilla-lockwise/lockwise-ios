/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import FxAUtils
import Account
import Shared
import Storage
import Deferred

class FakeProfile: FxAUtils.Profile {
    func getAccount() -> Account.FirefoxAccount? {
        return nil
    }

    func setAccount(_ account: Account.FirefoxAccount) {

    }

    var prefs: Shared.Prefs

    var logins: Storage.BrowserLogins & ResettableSyncStorage & SyncableLogins

    var isShutdown: Bool {
        return true
    }

    func shutdown() {

    }

    func reopen() {

    }

    func localName() -> String {
        return "lockbox-fake-profile"
    }

    var accountConfiguration: Account.FirefoxAccountConfiguration {
        return Account.StageFirefoxAccountConfiguration()
    }

    func hasAccount() -> Bool {
        return false
    }

    func hasSyncableAccount() -> Bool {
        return false
    }

    func removeAccount() -> Shared.Success {
        return Shared.Success()
    }

    func flushAccount() {

    }

    var syncManager: SyncManager!

    var isChinaEdition: Bool {
        return false
    }

    init() {
        prefs = DefaultsPrefs()
        logins = FakeBrowserLogins()
    }
}

class FakeBrowserLogins: BrowserLogins & ResettableSyncStorage & SyncableLogins {
    func resetClient() -> Success {
        return Success()
    }

    func deleteByGUID(_ guid: GUID, deletedAt: Timestamp) -> Success {
        return Success()
    }

    func applyChangedLogin(_ upstream: ServerLogin) -> Success {
        return Success()
    }

    func getModifiedLoginsToUpload() -> Deferred<Maybe<[Login]>> {
        return Deferred<Maybe<[Login]>>()
    }

    func getDeletedLoginsToUpload() -> Deferred<Maybe<[GUID]>> {
        return Deferred<Maybe<[GUID]>>()
    }

    func markAsSynchronized<T>(_: T, modified: Timestamp) -> Deferred<Maybe<Timestamp>> where T : Collection, T.Element == GUID {
        return Deferred<Maybe<Timestamp>>()
    }

    func markAsDeleted<T>(_ guids: T) -> Success where T : Collection, T.Element == GUID {
        return Success()
    }

    func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        return Deferred<Maybe<Bool>>()
    }

    func onRemovedAccount() -> Success {
        return Success()
    }

    func getUsageDataForLoginByGUID(_ guid: GUID) -> Deferred<Maybe<LoginUsageData>> {
        return Deferred<Maybe<LoginUsageData>>()
    }

    func getLoginDataForGUID(_ guid: GUID) -> Deferred<Maybe<Login>> {
        return Deferred<Maybe<Login>>()
    }

    func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace) -> Deferred<Maybe<Cursor<LoginData>>> {
        return Deferred<Maybe<Cursor<LoginData>>>()
    }

    func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace, withUsername username: String?) -> Deferred<Maybe<Cursor<LoginData>>> {
        return Deferred<Maybe<Cursor<LoginData>>>()
    }

    func getAllLogins() -> Deferred<Maybe<Cursor<Login>>> {
        return Deferred<Maybe<Cursor<Login>>>()
    }

    func searchLoginsWithQuery(_ query: String?) -> Deferred<Maybe<Cursor<Login>>> {
        return Deferred<Maybe<Cursor<Login>>>()
    }

    func addLogin(_ login: LoginData) -> Success {
        return Success()
    }

    func updateLoginByGUID(_ guid: GUID, new: LoginData, significant: Bool) -> Success {
        return Success()
    }

    func addUseOfLoginByGUID(_ guid: GUID) -> Success {
        return Success()
    }

    func removeLoginByGUID(_ guid: GUID) -> Success {
        return Success()
    }

    func removeLoginsWithGUIDs(_ guids: [GUID]) -> Success {
        return Success()
    }

    func removeAll() -> Success {
        return Success()
    }
}

class DefaultsPrefs: Prefs {
    func getBranchPrefix() -> String {
        return ""
    }

    func branch(_ branch: String) -> Prefs {
        return self
    }

    func setTimestamp(_ value: Timestamp, forKey defaultName: String) {

    }

    func setLong(_ value: UInt64, forKey defaultName: String) {

    }

    func setLong(_ value: Int64, forKey defaultName: String) {

    }

    func setInt(_ value: Int32, forKey defaultName: String) {

    }

    func setString(_ value: String, forKey defaultName: String) {

    }

    func setBool(_ value: Bool, forKey defaultName: String) {

    }

    func setObject(_ value: Any?, forKey defaultName: String) {

    }

    func stringForKey(_ defaultName: String) -> String? {
        return nil
    }

    func objectForKey<T>(_ defaultName: String) -> T? {
        return nil
    }

    func boolForKey(_ defaultName: String) -> Bool? {
        return nil
    }

    func intForKey(_ defaultName: String) -> Int32? {
        return nil
    }

    func timestampForKey(_ defaultName: String) -> Timestamp? {
        return nil
    }

    func longForKey(_ defaultName: String) -> Int64? {
        return nil
    }

    func unsignedLongForKey(_ defaultName: String) -> UInt64? {
        return nil
    }

    func stringArrayForKey(_ defaultName: String) -> [String]? {
        return nil
    }

    func arrayForKey(_ defaultName: String) -> [Any]? {
        return nil
    }

    func dictionaryForKey(_ defaultName: String) -> [String : Any]? {
        return nil
    }

    func removeObjectForKey(_ defaultName: String) {

    }

    func clearAll() {

    }


}

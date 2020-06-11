//
//  NetworkMetaDb.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/20.
//  Copyright © 2019 mugua. All rights reserved.
//

import Foundation
import SQLite
import SwiftDate

final class NetworkMetaDb {
    
    let path: String
    var db: Connection?
    var table: Table
    
    let id = Expression<Int64>("id")
    let key = Expression<String>("key")
    let value = Expression<Data>("value")
    let accessTime = Expression<Date>("accessTime")
    let expirationTime = Expression<Date>("expirationTime")
    let userId = Expression<String?>("userId")
    
    private var lock = pthread_rwlock_t()
    private let queue = DispatchQueue(label: "com.networkMetaDb.rw", qos: .default, attributes: .concurrent, autoreleaseFrequency: .workItem)
    private let kDatabaseName = "cachedb.sqlite3"
    private let kTableName = "networkcacheLC"
    
    deinit {
        pthread_rwlock_destroy(&lock)
    }
    
    init(path: String) {
        
        self.path = path.appending(kDatabaseName)
        self.table = Table(kTableName)
        initDb()
    }
    
    fileprivate func initDb() {
        do {
            self.db = try Connection(self.path)
            print("db path: \(self.path)")
        } catch {
            print(error.localizedDescription)
        }
        assert(self.db != nil)
        createTable()
    }
    
    fileprivate func createTable() {
        try! self.checkDb().run(self.table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(key, unique: true)
            t.column(value)
            t.column(accessTime)
            t.column(expirationTime)
            t.column(userId)
        })
    }
    
    fileprivate func checkDb() -> Connection {
        guard let _db = self.db else {
            fatalError("db can not open")
        }
        return _db
    }
}

extension NetworkMetaDb {
    
    func save(_ value: Data, key: String) {
        around {
            queue.async {[weak self] in
                guard let this = self else { return }
                do {
                    var result = false
                    try this.db?.transaction {
                        let filterTable = this.table.filter(this.key == key)
                        if try this.checkDb().run(filterTable.update(
                            this.key <- key,
                            this.value <- value,
                            this.userId <- LCUser.current().token?.userId
                        )) > 0 {
                            result = true
                            print("写入成功: \(result)")
                        } else {
                            let rowid = try this.checkDb().run(this.table.insert(
                                this.key <- key,
                                this.value <- value,
                                this.accessTime <- Date(),
                                this.expirationTime <- Date() + 7.days,
                                this.userId <- LCUser.current().token?.userId
                            ))
                            
                            result = (rowid > Int64(0)) ? true : false
                            print("写入成功: \(result)")
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    @discardableResult
    func value(forKey key: String) -> Data? {
        
        around {
            var result: Data?
            queue.sync(flags: .barrier) {
                let query = self.table.select(self.table[*])
                    .filter(self.key == key)
                    .filter(self.userId == LCUser.current().token?.userId)
                    .limit(1)
                
                do {
                    let rows = try self.checkDb().prepare(query)
                    
                    try self.db?.run(query.update(self.accessTime <- Date()))
                    
                    if let row = Array(rows).last {
                        result = row[self.value]
                        
                    } else {
                    }
                } catch  {
                    print(error.localizedDescription)
                }
            }
            return result
        }
    }
    
    @discardableResult
    func deleteExpiredData() -> Bool {
        around {
            var result = -1
            let expired = self.table.select(self.table[*])
                .filter(self.accessTime > self.expirationTime)
            do {
                result = try self.checkDb().run(expired.delete())
            } catch {
                
                print("delete expiredData failed: \(error)")
                result = -1
            }
            return result > 0
        }
    }
    
    @discardableResult
    func deleteValueBy(_ userId: String?) -> Bool {
        around {
            var result = -1
            queue.sync(flags: .barrier) {
                let target = self.table.select(self.table[*])
                    .filter(self.userId == userId)
                do {
                    result = try self.checkDb().run(target.delete())
                    
                } catch {
                    print("delete failed: \(error)")
                    result = -1
                }
            }
            return result > 0
        }
    }
    
    @discardableResult
    func deleteAll() -> Bool {
        return around {
            var result = -1
            queue.sync(flags: .barrier) {
                do {
                    result = try self.checkDb().run(self.table.delete())
                } catch {
                    print("delete failed: \(error)")
                    result = -1
                }
            }
            return result > 0
        }
    }
}


extension NetworkMetaDb {
    
    func around<T>(_ closure: () -> T) -> T {
        pthread_rwlock_trywrlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        return closure()
    }
}

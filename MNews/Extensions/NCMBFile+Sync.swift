//
//  NCMBFile+Sync.swift
//  MNews
//
//  Created by 千葉 俊輝 on 2016/02/28.
//  Copyright © 2016年 Toshiki Chiba. All rights reserved.
//

import Foundation
import NCMB

public extension NCMBFile {
    public func getFileData() -> NSData {
        let request = NCMBURLConnection(path: "files/\(self.name)", method: "GET", data: nil)
        
        do {
            if let responseData = try request.syncConnection() as? NSData {
                return responseData
            }
        }
        catch {
        }
        
        return NSData()
    }
}
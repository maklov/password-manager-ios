//
//  VaultModels.swift
//  password-manager-ios
//
//  Created by DevMac on 24/03/2026.
//
import Foundation

  

struct VaultEntry: Identifiable, Codable {
    let id: String
    var title: String
    var username: String
    var website: String
    var ciphertext: String
    var nonce: String
    var category: String
    var lastModified: String
    var iconName: String
}

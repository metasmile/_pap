//
// Created by BLACKGENE on 20/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

/*
BApp naming basic rule

App displayName: A noun with uppercase for first chr. (e.g. Finder (o), Find (x), finder(x) )
App class name: {DisplayName}App
                {DisplayName}AppDockContent
                {DisplayName}AppDefaults
                {DisplayName}AppTask
                 ...

Identifier: "com.stells.pap.{displayname-lowercase}"
File name: {DisplayName}.BApp.swift
           {DisplayName}.BApp.Assets.xcassets

*/

protocol BApp: App, PersistableApp{}
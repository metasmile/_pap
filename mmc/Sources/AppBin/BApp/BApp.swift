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
File name: {DisplayName(App)!}.BApp.swift
           {DisplayName(App)!}.BApp.Assets.xcassets

Identifier (Optional): "com.stells.mmc.{displayname-lowercase}"


*/

protocol BApp: TaskApp, PersistableApp{}
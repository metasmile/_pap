//
// Created by BLACKGENE on 20/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

/*
SApp naming basic rule is following BApp
*/

protocol SApp: PersistableApp{}


/*

Special Activation Period Limitations

- SNSEngagementPayment - Each 5 day
- FBShareTypeDownloadMessagerPayment - Each new shortStringVersion after paid
- FBShareTypeDownloadUrlPayment - Each 7 day after paid

*/
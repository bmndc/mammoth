//
//  UITableView+SafeScrollToRow.swift
//  Mammoth
//
//  Created by Riley on 11/30/23
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

extension UITableView {
    // First verify index exists, then scroll to it.
    func safeScrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        if indexPath.section < numberOfSections,
           indexPath.row < numberOfRows(inSection: indexPath.section)
        {
            scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
        } else {
            setContentOffset(.zero, animated: true)
            log.error("Tried to scroll to a non-existant indexPath: \(indexPath)")
        }
    }
}

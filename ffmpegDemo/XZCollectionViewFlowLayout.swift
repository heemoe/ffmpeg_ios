//
//  XZCollectionViewFlowLayout.swift
//  ffmpegDemo
//
//  Created by gdmobZHX on 16/1/21.
//  Copyright © 2016年 gdmobZHX. All rights reserved.
//

import UIKit

class XZCollectionViewFlowLayout: UICollectionViewFlowLayout {
    // 计算位置大小 更新
    override func prepareLayout() {
        
    }
    
    // cell content size 
    override func collectionViewContentSize() -> CGSize {
        return CGSizeZero
    }
    
    // 布局 Layout
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return nil
    }
}

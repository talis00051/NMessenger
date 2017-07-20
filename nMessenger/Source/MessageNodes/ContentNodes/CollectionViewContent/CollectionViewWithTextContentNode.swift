//
//  CollectionViewWithTextContentNode.swift
//  nMessenger
//
//  Created by Alexander Dodatko on 7/18/17.
//  Copyright © 2017 Ebay Inc. All rights reserved.
//

import Foundation
import AsyncDisplayKit


open class CollectionViewWithTextContentNode: CollectionViewContentNode
{
    public var textMessageNode: ASTextNode?
    public var timestampNode  : ASTextNode?
    
    override open func layoutSpecThatFits(
        _ constrainedSize: ASSizeRange)
    -> ASLayoutSpec
    {
        guard let textMessageNodeUnwrap = self.textMessageNode,
              let timestampNodeUnwrap   = self.timestampNode
        else
        {
            return super.layoutSpecThatFits(constrainedSize)
        }
        

        // ====
        //
        let cellsLayout = super.layoutSpecThatFits(constrainedSize)
        
        let imagesPaddingInsets =
            UIEdgeInsets(
                top: 4,
                left: 15,
                bottom: 15,
                right: 4)
        let imagesPadding =
            ASInsetLayoutSpec(
                insets: imagesPaddingInsets,
                child: cellsLayout)
        
        
        // ==== timestampNode
        //
        let timespampPaddingInsets =
            UIEdgeInsets(
                top: 10,
                left: 15,
                bottom: 0,
                right: 0)
        let timestampPadding =
            ASInsetLayoutSpec(
                insets: timespampPaddingInsets,
                child: timestampNodeUnwrap)
        
        // ==== textMessageNode
        //
        let labelPaddingInsets =
            UIEdgeInsets(
                top: 5,
                left: 15,
                bottom: 0,
                right: 0)
        let labelPadding =
            ASInsetLayoutSpec(
                insets: labelPaddingInsets,
                child: textMessageNodeUnwrap)
        
        
        // ====
        //
        let result =
            ASStackLayoutSpec(
                direction: .vertical,
                spacing: 5,
                justifyContent: .start,
                alignItems: .start,
                children: [timestampPadding, labelPadding, imagesPadding])
        
        return result
    }
}


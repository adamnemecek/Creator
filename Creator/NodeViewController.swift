//
//  NodeViewController.swift
//  Creator
//
//  Created by Litherum on 4/11/15.
//  Copyright (c) 2015 Litherum. All rights reserved.
//

import Cocoa

class NodeViewController: NSViewController {
    var node: Node!
    weak var graphViewController: GraphViewController!
    weak var leadingConstraint: NSLayoutConstraint!
    weak var topConstraint: NSLayoutConstraint!
    var draggingStartPoint: NSPoint?
    @IBOutlet var titleView: NodeTitleTextField!
    @IBOutlet var inputsView: NSStackView!
    @IBOutlet var outputsView: NSStackView!
    @IBOutlet var detailsPopover: NSPopover!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?, node: Node) {
        self.node = node
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override func viewDidLoad() {
        titleView.graphViewController = graphViewController
        titleView.nodeViewController = self
    }

    func addInputOutputView(value: String, alignment: NSTextAlignment, input: Bool, index: UInt) {
        var inputOutputTextField = NodeInputOutputTextField(graphViewController: graphViewController, nodeViewController: self, input: input, index: index, alignment: alignment, value: value)

        (input ? inputsView : outputsView).addView(inputOutputTextField, inGravity: .Center)
    }

    func nodeTitleMouseDown(mouseLocation: NSPoint) {
        var startPoint = NSPoint(x: leadingConstraint.constant, y: topConstraint.constant)
        startPoint.x -= mouseLocation.x
        startPoint.y += mouseLocation.y
        draggingStartPoint = startPoint
    }

    func nodeTitleMouseDragged(mouseLocation: NSPoint) {
        if let startPoint = draggingStartPoint {
            leadingConstraint.constant = startPoint.x + mouseLocation.x
            topConstraint.constant = startPoint.y - mouseLocation.y
            node.positionX = Float(leadingConstraint.constant)
            node.positionY = Float(topConstraint.constant)
            graphViewController.updateEdgeViews()
        }
    }

    func nodeTitleMouseUp(mouseLocation: NSPoint) {
        draggingStartPoint = nil
    }

    func showDetails() {
        if let vertexShaderNode = node as? VertexShaderNode {
            detailsPopover.contentViewController = VertexShaderDetailsViewController(nibName: "VertexShaderDetailsViewController", bundle: nil, node: vertexShaderNode)!
        } else {
            detailsPopover.contentViewController = NSViewController(nibName: "NodeDetailsViewController", bundle: nil)!
        }
        detailsPopover.showRelativeToRect(view.bounds, ofView: view, preferredEdge: NSMaxXEdge)
    }
}

//
//  GraphViewController.swift
//  Creator
//
//  Created by Litherum on 4/11/15.
//  Copyright (c) 2015 Litherum. All rights reserved.
//

import Cocoa

class GraphViewController: NSViewController {
    lazy var frame: Frame? = self.fetchFrame()
    lazy var nullNode: NullNode? = self.fetchNullNode()
    var nodeViewControllerToNodeDictionary: [NodeViewController: Node] = [:]
    var nodeToNodeViewControllerDictionary: [Node: NodeViewController] = [:]
    var managedObjectContext: NSManagedObjectContext!
    var managedObjectModel: AnyObject!

    @IBOutlet var connectionsView: ConnectionsView!

    enum DragOperation {
        case Move(Node, NSPoint)
        case Connect(Node, UInt)
    }
    var dragOperation: DragOperation!

    func fetchFrame() -> Frame? {
        var frameRequest = managedObjectModel.fetchRequestFromTemplateWithName("FrameRequest", substitutionVariables: [:]) as NSFetchRequest!
        var error: NSError?
        let frames = managedObjectContext.executeFetchRequest(frameRequest, error: &error) as! [Frame]!
        if error != nil {
            return nil
        }
        if frames.count == 0 {
            return NSEntityDescription.insertNewObjectForEntityForName("Frame", inManagedObjectContext: managedObjectContext) as? Frame
        } else {
            return frames[0]
        }
    }

    func fetchNullNode() -> NullNode? {
        var nullNodeRequest = managedObjectModel.fetchRequestFromTemplateWithName("NullNodeRequest", substitutionVariables: [:]) as NSFetchRequest!
        var error: NSError?
        let nullNodes = managedObjectContext.executeFetchRequest(nullNodeRequest, error: &error) as! [NullNode]!
        if error != nil {
            return nil
        }
        if nullNodes.count == 0 {
            var result = NSEntityDescription.insertNewObjectForEntityForName("NullNode", inManagedObjectContext: managedObjectContext) as? NullNode
            result!.frame = frame!
            result!.title = "NULL NODE"
            return result
        } else {
            return nullNodes[0]
        }
    }

    func createConstantBufferNode() {
        var newNode = NSEntityDescription.insertNewObjectForEntityForName("ConstantBufferNode", inManagedObjectContext: managedObjectContext) as! ConstantBufferNode
        newNode.populate(nullNode!, context: managedObjectContext)
        newNode.positionX = 13
        newNode.positionY = 17
        newNode.title = "Constant Buffer"
        newNode.payload = "test".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
        newNode.frame = frame!
        addNodeView(newNode)
    }

    func createVertexShaderNode() {
        var newNode = NSEntityDescription.insertNewObjectForEntityForName("VertexShaderNode", inManagedObjectContext: managedObjectContext) as! VertexShaderNode
        newNode.populate(nullNode!, context: managedObjectContext)
        newNode.positionX = 13
        newNode.positionY = 17
        newNode.title = "Vertex Shader"
        newNode.source = "test"
        newNode.frame = frame!
        addNodeView(newNode)
    }

    func createFragmentShaderNode() {
        var newNode = NSEntityDescription.insertNewObjectForEntityForName("FragmentShaderNode", inManagedObjectContext: managedObjectContext) as! FragmentShaderNode
        newNode.populate(nullNode!, context: managedObjectContext)
        newNode.positionX = 13
        newNode.positionY = 17
        newNode.title = "Fragment Shader"
        newNode.source = "test"
        newNode.frame = frame!
        addNodeView(newNode)
    }

    func createConstantFloatNode() {
        var newNode = NSEntityDescription.insertNewObjectForEntityForName("ConstantFloatNode", inManagedObjectContext: managedObjectContext) as! ConstantFloatNode
        newNode.populate(nullNode!, context: managedObjectContext)
        newNode.positionX = 13
        newNode.positionY = 17
        newNode.title = "Constant Float"
        newNode.payload = 15
        newNode.frame = frame!
        addNodeView(newNode)
    }

    func populate() {
        var nodeRequest = managedObjectModel.fetchRequestFromTemplateWithName("NodeRequest", substitutionVariables: [:]) as NSFetchRequest!
        var error: NSError?
        let nodes = managedObjectContext.executeFetchRequest(nodeRequest, error: &error) as! [Node]!
        if error != nil {
            return
        }
        for node in nodes {
            if node.frame != frame || node is NullNode {
                continue
            }
            addNodeView(node)
        }
        updateEdgeViews()
    }

    func updateEdgeViews() {
        connectionsView.connections = []
        var edgeRequest = managedObjectModel.fetchRequestFromTemplateWithName("EdgeRequest", substitutionVariables: [:]) as NSFetchRequest!
        var error: NSError?
        let edges = managedObjectContext.executeFetchRequest(edgeRequest, error: &error) as! [Edge]!
        if error != nil {
            return
        }
        for edge in edges {
            if edge.source.frame != frame || edge.destination.frame != frame || edge.source is NullNode || edge.destination is NullNode {
                continue
            }
            addEdgeView(nodeToNodeViewControllerDictionary[edge.source]!.inputsView.views[Int(edge.sourceIndex)] as! NodeInputOutputTextField, outputTextField: nodeToNodeViewControllerDictionary[edge.destination]!.outputsView.views[Int(edge.destinationIndex)] as! NodeInputOutputTextField)
        }
    }

    func addNodeView(node: Node) {
        let nodeViewController = NodeViewController(nibName: "NodeViewController", bundle: nil) as NodeViewController!
        nodeViewController.graphViewController = self
        nodeViewControllerToNodeDictionary[nodeViewController] = node
        nodeToNodeViewControllerDictionary[node] = nodeViewController
        addChildViewController(nodeViewController)
        view.addSubview(nodeViewController.view)
        let leadingConstraint = NSLayoutConstraint(item: nodeViewController.view, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: CGFloat(node.positionX))
        let topConstraint = NSLayoutConstraint(item: nodeViewController.view, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: CGFloat(node.positionY))
        view.addConstraint(leadingConstraint)
        view.addConstraint(topConstraint)
        nodeViewController.leadingConstraint = leadingConstraint
        nodeViewController.topConstraint = topConstraint
        nodeViewController.titleView.stringValue = node.title

        for i in 0 ..< node.inputs.count {
            nodeViewController.addInputOutputView("aaa", alignment: .LeftTextAlignment, input: true, index: UInt(i))
        }
        for i in 0 ..< node.outputs.count {
            nodeViewController.addInputOutputView("aaa", alignment: .RightTextAlignment, input: false, index: UInt(i))
        }
    }

    func addEdgeView(inputTextField: NodeInputOutputTextField, outputTextField: NodeInputOutputTextField) {
        view.layoutSubtreeIfNeeded()
        let startPoint = connectionsView.convertPoint(NSMakePoint(0, (inputTextField.bounds.origin.y + inputTextField.bounds.maxY) / 2), fromView: inputTextField)
        let endPoint = connectionsView.convertPoint(NSMakePoint(outputTextField.bounds.maxX, (outputTextField.bounds.origin.y + outputTextField.bounds.maxY) / 2), fromView: outputTextField)
        connectionsView.connections.append(Connection(startPoint: startPoint, endPoint: endPoint))
        connectionsView.setNeedsDisplayInRect(connectionsView.bounds)
    }

    func nodeInputOutputMouseDown(nodeViewController: NodeViewController, index: UInt) {
        dragOperation = .Connect(nodeViewControllerToNodeDictionary[nodeViewController]!, index)
    }

    func nodeInputOutputMouseUp(nodeViewController: NodeViewController, index: UInt, mouseLocation: NSPoint) {
        if let dragOperation = dragOperation {
            switch (dragOperation) {
            case .Connect(let inputNode, let inputIndex):
                if let hitView = view.hitTest(view.superview!.convertPoint(mouseLocation, fromView: nil)) {
                    if let nodeInputOutputTextField = hitView as? NodeInputOutputTextField {
                        let outputNode = nodeViewControllerToNodeDictionary[nodeInputOutputTextField.nodeViewController]!
                        let outputIndex = nodeInputOutputTextField.index
                        if (inputNode.inputs[Int(inputIndex)] as! Edge).destination is NullNode && (outputNode.outputs[Int(outputIndex)] as! Edge).source is NullNode {
                            managedObjectContext.deleteObject(inputNode.inputs[Int(inputIndex)] as! Edge)
                            managedObjectContext.deleteObject(outputNode.outputs[Int(outputIndex)] as! Edge)
                            var edge = NSEntityDescription.insertNewObjectForEntityForName("Edge", inManagedObjectContext: managedObjectContext) as! Edge
                            edge.sourceIndex = Int32(index)
                            edge.destinationIndex = Int32(outputIndex)
                            var inputSet = inputNode.mutableOrderedSetValueForKey("inputs")
                            inputSet.removeObjectAtIndex(Int(index))
                            inputSet.insertObject(edge, atIndex: Int(index))
                            var outputSet = outputNode.mutableOrderedSetValueForKey("outputs")
                            outputSet.removeObjectAtIndex(Int(outputIndex))
                            outputSet.insertObject(inputNode.inputs[Int(inputIndex)], atIndex: Int(outputIndex))

                            addEdgeView(nodeToNodeViewControllerDictionary[inputNode]!.inputsView.views[Int(inputIndex)] as! NodeInputOutputTextField, outputTextField: nodeInputOutputTextField)
                        }
                    }
                }
                connectionsView.connectionInFlight = nil
                connectionsView.setNeedsDisplayInRect(connectionsView.bounds)
            default:
                break
            }
        }
        dragOperation = nil
    }

    func nodeTitleMouseDown(nodeViewController: NodeViewController, mouseLocation: NSPoint) {
        var draggingStartPoint = NSPoint(x: nodeViewController.leadingConstraint.constant, y: nodeViewController.topConstraint.constant)
        draggingStartPoint.x -= mouseLocation.x
        draggingStartPoint.y += mouseLocation.y
        dragOperation = .Move(nodeViewControllerToNodeDictionary[nodeViewController]!, draggingStartPoint)
    }

    func nodeTitleMouseUp(nodeViewController: NodeViewController, mouseLocation: NSPoint) {
        dragOperation = nil
    }

    override func mouseDragged(theEvent: NSEvent) {
        if let op = dragOperation {
            let currentMouseLocation = theEvent.locationInWindow
            switch op {
            case .Move(let node, let position):
                let viewController = nodeToNodeViewControllerDictionary[node]!
                viewController.leadingConstraint.constant = position.x + currentMouseLocation.x
                viewController.topConstraint.constant = position.y - currentMouseLocation.y
                node.positionX = Float(viewController.leadingConstraint.constant)
                node.positionY = Float(viewController.topConstraint.constant)
                updateEdgeViews()
            case .Connect(let node, let index):
                let mouseLocation = connectionsView.convertPoint(currentMouseLocation, fromView: nil)
                if connectionsView.connectionInFlight != nil {
                    connectionsView.connectionInFlight!.endPoint = mouseLocation
                } else {
                    let inputView = nodeToNodeViewControllerDictionary[node]!.inputsView.views[Int(index)] as! NodeInputOutputTextField
                    let startPoint = connectionsView.convertPoint(NSMakePoint(0, (inputView.bounds.origin.y + inputView.bounds.maxY) / 2), fromView: inputView)
                    connectionsView.connectionInFlight = Connection(startPoint: startPoint, endPoint: mouseLocation)
                }
                connectionsView.setNeedsDisplayInRect(connectionsView.bounds)
            }
        }
    }

    override func mouseUp(theEvent: NSEvent) {
        connectionsView.connectionInFlight = nil
        dragOperation = nil
        connectionsView.setNeedsDisplayInRect(connectionsView.bounds)
    }
}
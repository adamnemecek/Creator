//
//  GraphViewController.swift
//  Creator
//
//  Created by Litherum on 4/11/15.
//  Copyright (c) 2015 Litherum. All rights reserved.
//

import Cocoa

class GraphViewController: NSViewController {
    var frame: Frame!
    lazy var nullNode: NullNode! = self.fetchNullNode()
    var nodeViewControllerToNodeDictionary: [NodeViewController: Node] = [:]
    var nodeToNodeViewControllerDictionary: [Node: NodeViewController] = [:]
    var managedObjectContext: NSManagedObjectContext!
    var managedObjectModel: AnyObject!

    @IBOutlet var connectionsView: ConnectionsView!

    var connectionInProgress: (Node, Int)?

    func fetchNullNode() -> NullNode? {
        var nullNodeRequest = managedObjectModel.fetchRequestFromTemplateWithName("NullNodeRequest", substitutionVariables: [:]) as NSFetchRequest!
        var error: NSError?
        let nullNodes = managedObjectContext.executeFetchRequest(nullNodeRequest, error: &error) as! [NullNode]!
        if error != nil {
            return nil
        }
        if nullNodes.count == 0 {
            var node = NSEntityDescription.insertNewObjectForEntityForName("NullNode", inManagedObjectContext: managedObjectContext) as! NullNode
            node.title = "NULL NODE"
            return node
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
        newNode.payload = NSData()
        addNodeView(newNode)
    }

    func createVertexShaderNode() {
        var newNode = NSEntityDescription.insertNewObjectForEntityForName("VertexShaderNode", inManagedObjectContext: managedObjectContext) as! VertexShaderNode
        var error: NSError?
        newNode.source = String(contentsOfFile: NSBundle.mainBundle().pathForResource("DefaultVertexShader", ofType: "vs")!, encoding: NSUTF8StringEncoding, error: &error)!
        newNode.populate(nullNode!, context: managedObjectContext)
        newNode.positionX = 13
        newNode.positionY = 17
        newNode.title = "Vertex Shader"
        addNodeView(newNode)
    }

    func createFragmentShaderNode() {
        var newNode = NSEntityDescription.insertNewObjectForEntityForName("FragmentShaderNode", inManagedObjectContext: managedObjectContext) as! FragmentShaderNode
        var error: NSError?
        newNode.source = String(contentsOfFile: NSBundle.mainBundle().pathForResource("DefaultFragmentShader", ofType: "fs")!, encoding: NSUTF8StringEncoding, error: &error)!
        newNode.populate(nullNode!, context: managedObjectContext)
        newNode.positionX = 13
        newNode.positionY = 17
        newNode.title = "Fragment Shader"
        addNodeView(newNode)
    }

    func createConstantFloatNode() {
        var newNode = NSEntityDescription.insertNewObjectForEntityForName("ConstantFloatNode", inManagedObjectContext: managedObjectContext) as! ConstantFloatNode
        newNode.populate(nullNode!, context: managedObjectContext)
        newNode.positionX = 13
        newNode.positionY = 17
        newNode.title = "Constant Float"
        newNode.payload = 15
        newNode.minValue = 0
        newNode.maxValue = 100
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
            if node is NullNode {
                continue
            }
            // FIXME: Find a better way to factor this
            if let constantBufferNode = node as? ConstantBufferNode {
                constantBufferNode.upload()
            }
            if node is Frame {
                frame = node as! Frame
            }
            addNodeView(node)
        }
        if frame == nil {
            frame = NSEntityDescription.insertNewObjectForEntityForName("Frame", inManagedObjectContext: managedObjectContext) as! Frame
            frame.positionX = 13
            frame.positionY = 17
            frame.title = "Frame"
            addNodeView(frame)
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
            if edge.source.node is NullNode || edge.destination.node is NullNode {
                continue
            }
            let inputTextField = nodeToNodeViewControllerDictionary[edge.source.node]!.inputsView.views[Int(edge.source.index)] as! NodeInputOutputTextField
            let outputTextField = nodeToNodeViewControllerDictionary[edge.destination.node]!.outputsView.views[Int(edge.destination.index)] as! NodeInputOutputTextField
            addEdgeView(inputTextField, outputTextField: outputTextField)
        }
    }

    func addNodeView(node: Node) {
        let nodeViewController = NodeViewController(nibName: "NodeViewController", bundle: nil, node: node, nullNode: nullNode, managedObjectContext: managedObjectContext)!
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
            nodeViewController.addInputOutputView((node.inputs[i] as! InputPort).title, input: true)
        }
        for i in 0 ..< node.outputs.count {
            nodeViewController.addInputOutputView((node.outputs[i] as! OutputPort).title, input: false)
        }
    }

    func addEdgeView(inputTextField: NodeInputOutputTextField, outputTextField: NodeInputOutputTextField) {
        view.layoutSubtreeIfNeeded()
        let startPoint = connectionsView.convertPoint(NSMakePoint(0, (inputTextField.bounds.origin.y + inputTextField.bounds.maxY) / 2), fromView: inputTextField)
        let endPoint = connectionsView.convertPoint(NSMakePoint(outputTextField.bounds.maxX, (outputTextField.bounds.origin.y + outputTextField.bounds.maxY) / 2), fromView: outputTextField)
        connectionsView.connections.append(Connection(startPoint: startPoint, endPoint: endPoint))
        redrawConnectionsView()
    }

    func redrawConnectionsView() {
        connectionsView.setNeedsDisplayInRect(connectionsView.bounds)
    }

    func nodeInputOutputMouseDown(nodeViewController: NodeViewController, index: Int) {
        connectionInProgress = (nodeViewControllerToNodeDictionary[nodeViewController]!, index)
    }

    func nodeInputOutputMouseUp(nodeViewController: NodeViewController, index: Int, mouseLocation: NSPoint) {
        if let (let inputNode, let inputIndex) = connectionInProgress {
            if let hitView = view.hitTest(view.superview!.convertPoint(mouseLocation, fromView: nil)) {
                if let nodeInputOutputTextField = hitView as? NodeInputOutputTextField {
                    let outputNode = nodeViewControllerToNodeDictionary[nodeInputOutputTextField.nodeViewController]!
                    let outputIndex = nodeInputOutputTextField.index
                    let inputPort = inputNode.inputs[inputIndex] as! InputPort
                    let outputPort = outputNode.outputs[outputIndex] as! OutputPort
                    if inputPort.edge.destination.node is NullNode && outputPort.edge.source.node is NullNode {
                        let nullNodeInputPort = outputPort.edge.source
                        let nullNodeOutputPort = inputPort.edge.destination
                        managedObjectContext.deleteObject(inputPort.edge)
                        managedObjectContext.deleteObject(outputPort.edge)

                        for i in Int(nullNodeInputPort.index) ..< nullNode!.inputs.count {
                            (nullNode!.inputs[i] as! InputPort).index--
                        }
                        for i in Int(nullNodeOutputPort.index) ..< nullNode!.outputs.count {
                            (nullNode!.outputs[i] as! OutputPort).index--
                        }
                        managedObjectContext.deleteObject(nullNodeInputPort)
                        managedObjectContext.deleteObject(nullNodeOutputPort)

                        var edge = NSEntityDescription.insertNewObjectForEntityForName("Edge", inManagedObjectContext: managedObjectContext) as! Edge
                        inputPort.edge = edge
                        outputPort.edge = edge

                        addEdgeView(nodeToNodeViewControllerDictionary[inputNode]!.inputsView.views[inputIndex] as! NodeInputOutputTextField, outputTextField: nodeInputOutputTextField)

                        if let inputFragmentShader = inputNode as? FragmentShaderNode {
                            if let outputVertexShader = outputNode as? VertexShaderNode {
                                var newProgram = NSEntityDescription.insertNewObjectForEntityForName("Program", inManagedObjectContext: managedObjectContext) as! Program
                                newProgram.vertexShader = outputVertexShader
                                newProgram.fragmentShader = inputFragmentShader
                                let linkLog = newProgram.link()
                                if let log = linkLog {
                                    println("Could not link! Log:")
                                    println(log)
                                    return
                                }

                                // FIXME: Find a better way of getting the NodeViewController
                                newProgram.iterateOverAttributes({(index: GLuint, name: String, size: GLint, type: GLenum) in
                                    nodeInputOutputTextField.nodeViewController.addAttributeInput(index, name: name, size: size, type: type)
                                })

                                newProgram.iterateOverUniforms({(index: GLuint, name: String, size: GLint, type: GLenum) in
                                    nodeInputOutputTextField.nodeViewController.addUniformInput(index, name: name, size: size, type: type)
                                })

                                updateEdgeViews()
                            }
                        }
                    }
                }
            }
            connectionsView.connectionInFlight = nil
            connectionsView.setNeedsDisplayInRect(connectionsView.bounds)
        }
        connectionInProgress = nil
    }

    override func mouseDragged(theEvent: NSEvent) {
        if let (let node, let index) = connectionInProgress {
            let currentMouseLocation = theEvent.locationInWindow
            let mouseLocation = connectionsView.convertPoint(currentMouseLocation, fromView: nil)
            if connectionsView.connectionInFlight != nil {
                connectionsView.connectionInFlight!.endPoint = mouseLocation
            } else {
                let inputView = nodeToNodeViewControllerDictionary[node]!.inputsView.views[index] as! NodeInputOutputTextField
                let startPoint = connectionsView.convertPoint(NSMakePoint(0, (inputView.bounds.origin.y + inputView.bounds.maxY) / 2), fromView: inputView)
                connectionsView.connectionInFlight = Connection(startPoint: startPoint, endPoint: mouseLocation)
            }
            connectionsView.setNeedsDisplayInRect(connectionsView.bounds)
        }
    }

}
//
//  Mediator.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-29.
//

import Combine

public typealias Mediator = Subject
public typealias CurrentValueMediator<EventType> = CurrentValueSubject<EventType, Never>
public typealias PassthroughMediator<EventType> = PassthroughSubject<EventType, Never>

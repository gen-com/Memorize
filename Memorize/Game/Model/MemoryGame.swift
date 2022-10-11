//
//  MemoryGame.swift
//  Memorize
//
//  Created by Byeongjo Koo on 2022/07/30.
//

import Foundation

struct MemoryGame<CardContent: Equatable> {
    
    // MARK: Alias(es)
    
    typealias Card = CardSet.Card
    
    // MARK: Property(ies)
    
    private(set) var cardSet: CardSet
    private(set) var points: Int
    var isFinished: Bool {
        cardSet.isAllCardsMatched
    }
    
    // MARK: Initializer(s)
    
    init(numberOfPairsOfCards: Int, createCardContent: (Int) -> CardContent) {
        cardSet = CardSet(numberOfPairsOfCards: numberOfPairsOfCards, createCardContent: createCardContent)
        points = 0
    }
    
    // MARK: Choose Card
    
    mutating func choose(_ card: Card) -> MatchResult {
        let matchResult = cardSet.choose(card)
        switch matchResult {
        case .match:
            points += 2
        case .noMatch:
            points -= 1
        case .none: break
        }
        return matchResult
    }
    
    mutating func flipAllCards() {
        cardSet.flipAllCards()
    }
}

// MARK: - Card Set

extension MemoryGame {
    
    enum MatchResult {
        
        case match
        case noMatch
        case none
    }
    
    struct CardSet {
        
        // MARK: Property(ies)
        
        private(set) var cards: [Card]
        private var indexOfOneAndOnlyFaceUpCard: Int? {
            get { cards.indices.filter({ cards[$0].isFaceUp }).oneAndOnly }
            set { cards.indices.forEach { cards[$0].isFaceUp = ($0 == newValue) } }
        }
        var isAllCardsMatched: Bool {
            cards.allSatisfy { $0.isMatched }
        }
        
        // MARK: Initializer(s)
        
        init(numberOfPairsOfCards: Int, createCardContent: (Int) -> CardContent) {
            cards = []
            for index in 0 ..< numberOfPairsOfCards {
                let content = createCardContent(index)
                cards.append(Card(content: content, id: index * 2))
                cards.append(Card(content: content, id: index * 2 + 1))
            }
            cards.shuffle()
        }
        
        // MARK: Method(s)
        
        mutating func flipAllCards() {
            for index in cards.indices {
                cards[index].isFaceUp.toggle()
            }
        }
        
        mutating func choose(_ card: Card) -> MatchResult {
            guard let indexOfChosenCard = cards.index(matching: card),
                  cards[indexOfChosenCard].isFaceUp == false,
                  cards[indexOfChosenCard].isMatched == false
            else { return .none }
            if let indexOfPotentialFaceUpCard = indexOfOneAndOnlyFaceUpCard {
                cards[indexOfChosenCard].isFaceUp = true
                return match(for: indexOfChosenCard, and: indexOfPotentialFaceUpCard)
            } else {
                indexOfOneAndOnlyFaceUpCard = indexOfChosenCard
            }
            return .none
        }
        
        private mutating func match(for lhs: Int, and rhs: Int) -> MatchResult {
            if cards[lhs].content == cards[rhs].content {
                cards[lhs].isMatched = true
                cards[rhs].isMatched = true
                return .match
            }
            return .noMatch
        }
    }
}

// MARK: - Match Result & Card

extension MemoryGame.CardSet {
    
    struct Card: Identifiable {
        
        var isFaceUp = false
        var isMatched = false
        let content: CardContent
        let id: Int
    }
}

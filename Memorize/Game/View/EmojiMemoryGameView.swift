//
//  EmojiMemoryGameView.swift
//  Memorize
//
//  Created by Byeongjo Koo on 2022/07/24.
//

import Combine
import SwiftUI

struct EmojiMemoryGameView: View {
    
    @ObservedObject var game: EmojiMemoryGame
    @Namespace private var dealingNamespace
    @State private var dealt: Set<Int> = []
    
    @State private var gameStartDate: Date?
    @State private var gameStartAnimationStream: AnyCancellable?
    @State private var gameStartAnimationTimeLeft = 0.0
    @State private var currentMatchingStatus = EmojiMemoryGame.MatchResult.none
    
    private var hapticFeedbackGenerator = UINotificationFeedbackGenerator()
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack {
                    if game.isFinished {
                        gameResult(in: proxy.size)
                    } else {
                        gameBody
                    }
                }
                VStack {
                    Spacer(minLength: 0)
                    if dealt.isEmpty {
                        startDescription
                    }
                    deckBody
                }
                if 0 < gameStartAnimationTimeLeft, gameStartAnimationTimeLeft <= AnimationConstants.frontRevealDuration {
                    RemainingCardsRevealTime(in: proxy.size)
                }
            }
        }
        .foregroundColor(game.themeColor)
        .padding()
    }
    
    init(game: EmojiMemoryGame) {
        self.game = game
    }
    
    private var isPlayable: Bool { gameStartAnimationStream == nil }
    
    // MARK: SubView(s)
    
    private var gameBody: some View {
        VStack {
            ZStack {
                matchingFeedback
                HStack {
                    if dealt.isEmpty == false && isPlayable {
                        restartButton
                    }
                    Spacer()
                    point
                }
            }
            gameBoard
        }
    }
    
    private var restartButton: some View {
        Button {
            restart()
        } label: {
            Text(Texts.newGame)
        }
    }
    
    private var matchingFeedback: some View {
        let result: String
        switch currentMatchingStatus {
        case .match:
            result = Texts.correct
        case .noMatch:
            result = Texts.wrong
        case .none:
            result = ""
        }
        return Text(result).font(.title).transition(.scale)
    }
    
    private var point: some View {
        Text(Texts.pointDescription + game.points).font(.body)
    }
    
    private var gameBoard: some View {
        AspectVGrid(items: game.cards, aspectRatio: DrawingConstants.cardAspectRatio) { card in
            if isUndealt(card) || (card.isMatched && !card.isFaceUp) {
                Color.clear
            } else {
                EmojiCardView(card: card)
                    .padding(DrawingConstants.cardPadding)
                    .matchedGeometryEffect(id: card.id, in: dealingNamespace)
                    .transition(.asymmetric(insertion: .identity, removal: .scale))
                    .zIndex(zIndex(of: card))
                    .onTapGesture {
                        withAnimation {
                            if isPlayable {
                                currentMatchingStatus = game.choose(card)
                                switch currentMatchingStatus {
                                case .match:
                                    hapticFeedbackGenerator.notificationOccurred(.success)
                                case .noMatch:
                                    hapticFeedbackGenerator.notificationOccurred(.error)
                                case .none: break
                                }
                                hapticFeedbackGenerator.prepare()
                            }
                        }
                    }
            }
        }
    }
    
    private var startDescription: some View {
        VStack {
            Text(Texts.startDescription)
            Image(systemName: ImageAsset.arrowtriangleDownFill)
                .padding(DrawingConstants.startDescriptionArrowPadding)
        }
    }
    
    private var deckBody: some View {
        ZStack {
            ForEach(game.cards.filter(isUndealt)) { card in
                EmojiCardView(card: card)
                    .matchedGeometryEffect(id: card.id, in: dealingNamespace)
                    .transition(.asymmetric(insertion: .opacity, removal: .identity))
                    .zIndex(zIndex(of: card))
            }
        }
        .frame(width: DrawingConstants.undealtWidth, height: DrawingConstants.undealtHeight)
        .onTapGesture {
            gameStartDate = Date()
            startAnimationStream()
            game.cards.forEach { card in withAnimation(dealAnimation(for: card)) { deal(card) } }
        }
        .transition(.asymmetric(insertion: .scale, removal: .identity))
    }
    
    private func RemainingCardsRevealTime(in size: CGSize) -> some View {
        Text("\(Int(gameStartAnimationTimeLeft))")
            .monospacedDigit()
            .shadow(color: .white, radius: DrawingConstants.remainingCardsRevealTimeShadowRadius)
            .font(.system(size: max(size.width, size.height) * DrawingConstants.remainingCardsRevealTimeFontRatio))
            .opacity(DrawingConstants.remainingCardsRevealTimeOpacity)
            .transition(.opacity)
    }
    
    private func gameResult(in size: CGSize) -> some View {
        VStack {
            Spacer()
            Text(Texts.gameResultPrefix + game.points + Texts.gameResultSuffix)
                .multilineTextAlignment(.center)
                .lineSpacing(Texts.gameResultLineSpacing)
                .font(.title)
            Spacer()
            HStack {
                RoundedRectangleShadowButton {
                    Text(Texts.no).foregroundColor(.white)
                }
                action: {
                    //TODO: Pop Back Action
                }
                .foregroundColor(.gray)
                RoundedRectangleShadowButton {
                    Text(Texts.yes).foregroundColor(.white)
                }
                action: {
                    restart()
                }
            }
            .frame(height: size.height * DrawingConstants.gameResultButtonHeightRatio)
        }
        .foregroundColor(.black)
        .transition(.asymmetric(insertion: .slide, removal: .opacity))
    }
    
    // MARK: Method(s)
    
    private func startAnimationStream() {
        gameStartAnimationStream = Timer.publish(every: AnimationConstants.trackingSecond, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { date in
                if let gameStartDate {
                    let timePassed = Double(Int(date.timeIntervalSince(gameStartDate)))
                    withAnimation {
                        gameStartAnimationTimeLeft = AnimationConstants.dealAndRevealDuration - timePassed
                    }
                    if timePassed == AnimationConstants.totalDealDuration {
                        withAnimation {
                            game.flipAllCards()
                        }
                    }
                    if timePassed == AnimationConstants.dealAndRevealDuration {
                        withAnimation {
                            game.flipAllCards()
                        }
                        gameStartAnimationStream = nil
                    }
                }
            }
    }
    
    private func deal(_ card: EmojiMemoryGame.Card) {
        dealt.insert(card.id)
    }
    
    private func isUndealt(_ card: EmojiMemoryGame.Card) -> Bool {
        dealt.contains(card.id) == false
    }
    
    private func dealAnimation(for card: EmojiMemoryGame.Card) -> Animation {
        var delay = 0.0
        if let index = game.cards.index(matching: card) {
            delay = Double(index) * (AnimationConstants.totalDealDuration / Double(game.cards.count))
        }
        return Animation.easeInOut(duration: AnimationConstants.dealDuration).delay(delay)
    }
    
    private func zIndex(of card: EmojiMemoryGame.Card) -> Double {
        -Double(game.cards.index(matching: card) ?? 0)
    }
    
    private func restart() {
        gameStartAnimationStream = nil
        currentMatchingStatus = .none
        withAnimation {
            dealt.removeAll()
            game.restartGame()
        }
    }
}

// MARK: - Constant(s)

extension EmojiMemoryGameView {
    
    private enum Texts {
        
        static let startDescription = "아래 카드를 누르면 게임이 시작됩니다."
        static let pointDescription = "점수: "
        static let gameResultPrefix = "축하합니다 !\n"
        static let gameResultSuffix = "점을 얻었습니다.\n다시 도전해 보실래요 ?"
        static let newGame = "다시하기"
        static let yes = "네"
        static let no = "아니요"
        
        static let correct = "✅"
        static let wrong = "🚫"
        
        static let gameResultLineSpacing: CGFloat = 10
    }
    
    private enum DrawingConstants {
        
        static let cardAspectRatio: CGFloat = 2 / 3
        static let cardPadding: CGFloat = 4
        
        static let startDescriptionArrowPadding: CGFloat = 2
        static let undealtHeight: CGFloat = 90
        static let undealtWidth = undealtHeight * cardAspectRatio
        
        static let gameResultButtonHeightRatio: CGFloat = 0.07
        
        static let remainingCardsRevealTimeShadowRadius: CGFloat = 5
        static let remainingCardsRevealTimeFontRatio: CGFloat = 0.2
        static let remainingCardsRevealTimeOpacity: CGFloat = 0.7
    }
    
    private enum AnimationConstants {
        
        static let trackingSecond = 1.0
        static let dealDuration = 0.5
        static let totalDealDuration = 2.0
        static let frontRevealDuration = 3.0
        static let dealAndRevealDuration = totalDealDuration + frontRevealDuration
    }
    
    private enum ImageAsset {
        
        static let arrowtriangleDownFill = "arrowtriangle.down.fill"
    }
}

// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        let game = EmojiMemoryGame()
        EmojiMemoryGameView(game: game)
    }
}

port module Main exposing (main)

import Array exposing (Array)
import CodinGame
import Json.Decode as Decode exposing (Decoder, Value)


{-| Port bringing the updated game data every turn.
-}
port stdin : (Value -> msg) -> Sub msg


{-| Port to give the new commands for this turn.
-}
port stdout : String -> Cmd msg


{-| Port to help debugging, will print using console.error().
-}
port stderr : String -> Cmd msg


main : Program Value GameState Value
main =
    CodinGame.worker
        { stdin = stdin identity
        , stdout = stdout
        , stderr = stderr
        }
        { init = init
        , turn =
            \value state ->
                case Decode.decodeValue decodeTurnData value of
                    Err err ->
                        -- Should not happen once we've written the decoder correctly
                        ( state
                        , ""
                        , Just (Decode.errorToString err)
                        )

                    Ok turnData ->
                        turn turnData state
        }


type alias GameState =
    { settings : InitData
    }


defaultGameState : GameState
defaultGameState =
    { settings =
        { numberOfCells = 0
        , cells = Array.fromList []
        }
    }


type alias InitData =
    { numberOfCells : Int
    , cells : Array Cell
    }


type alias Cell =
    { index : Int
    , richness : Int
    }


type alias TurnData =
    { day : Int
    , nutrients : Int
    , me : Player
    , other : Player
    , trees : List Tree
    , possibleActions : List String
    }


type alias Player =
    { sun : Int
    , score : Int
    , asleep : Bool
    }


type alias Tree =
    { index : Int
    , size : Int
    , isMine : Bool
    , isDormant : Bool
    }


{-| Function called at the game initialization.
The string contains initial game data.
-}
init : Value -> ( GameState, Maybe String )
init value =
    case Decode.decodeValue decodeInitData value of
        Err err ->
            -- Should not happen once we've written the decoder correctly
            ( defaultGameState, Just (Decode.errorToString err) )

        Ok initData ->
            ( { settings = initData }
            , Just "Initialization done!"
            )


{-|

  - Faire pousser un arbre de taille 1 en un arbre de taille 2 coûte 3 points de soleil + le nombre d'arbres de taille 2 que vous possédez déjà.
  - Faire pousser un arbre de taille 2 en un arbre de taille 3 coûte 7 points de soleil + le nombre d'arbres de taille 3 que vous possédez déjà.

-}
growingCost : List Tree -> Tree -> Int
growingCost trees tree =
    let
        sameSize =
            trees
                |> List.filter (\{ size } -> size == tree.size + 1)
                |> List.length
    in
    case tree.size of
        1 ->
            3 + sameSize

        2 ->
            7 + sameSize

        _ ->
            9999


{-| Function called during the game loop with the data of the current turn.
-}
turn : TurnData -> GameState -> ( GameState, String, Maybe String )
turn turnData state =
    let
        treesByRichness =
            turnData.trees
                |> List.filter .isMine
                |> List.sortBy
                    (\tree ->
                        Array.get tree.index state.settings.cells
                            |> Maybe.map .richness
                            |> Maybe.withDefault -1
                            |> (\x -> -x)
                    )

        decision =
            if turnData.day == 5 then
                lastTurn treesByRichness

            else
                firstTurns treesByRichness turnData
    in
    ( state
    , decision
    , Nothing
    )


lastTurn : List Tree -> String
lastTurn treesByRichness =
    treesByRichness
        |> List.filter (\tree -> tree.size == 3)
        |> List.head
        |> Maybe.map (\tree -> "COMPLETE " ++ String.fromInt tree.index)
        |> Maybe.withDefault "WAIT"


firstTurns : List Tree -> TurnData -> String
firstTurns treesByRichness turnData =
    let
        growIfPossible tree ( sun, decision ) =
            case decision of
                Just a ->
                    ( sun, Just a )

                Nothing ->
                    if tree.size == 3 then
                        ( sun, Nothing )

                    else if sun >= growingCost turnData.trees tree then
                        ( sun - growingCost turnData.trees tree, Just <| "GROW " ++ String.fromInt tree.index )

                    else
                        ( sun, Nothing )
    in
    List.foldl growIfPossible ( turnData.me.sun, Nothing ) treesByRichness
        |> Tuple.second
        |> Maybe.withDefault "WAIT"


decodeInitData : Decoder InitData
decodeInitData =
    Decode.map2 InitData
        (Decode.field "numberOfCells" Decode.int)
        (Decode.field "cells" (Decode.array decodeCell))


decodeCell : Decoder { index : Int, richness : Int }
decodeCell =
    Decode.map2 Cell
        (Decode.field "index" Decode.int)
        (Decode.field "richness" Decode.int)


decodeTurnData : Decoder TurnData
decodeTurnData =
    Decode.map6 TurnData
        (Decode.field "day" Decode.int)
        (Decode.field "nutrients" Decode.int)
        (Decode.field "me" decodePlayer)
        (Decode.field "other" decodePlayer)
        (Decode.field "trees" (Decode.list decodeTree))
        (Decode.field "possibleActions" (Decode.list Decode.string))


decodePlayer : Decoder Player
decodePlayer =
    Decode.map3 Player
        (Decode.field "sun" Decode.int)
        (Decode.field "score" Decode.int)
        (Decode.field "asleep" Decode.bool)


decodeTree : Decoder Tree
decodeTree =
    Decode.map4 Tree
        (Decode.field "index" Decode.int)
        (Decode.field "size" Decode.int)
        (Decode.field "isMine" Decode.bool)
        (Decode.field "isDormant" Decode.bool)

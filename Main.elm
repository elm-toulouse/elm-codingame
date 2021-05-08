port module Main exposing (main)

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
        , cells = []
        }
    }


type alias InitData =
    { numberOfCells : Int
    , cells : List Cell
    }


type alias Cell =
    { index : Int
    , richness : Int
    }


decodeInitData : Decoder InitData
decodeInitData =
    Decode.map2 InitData
        (Decode.field "numberOfCells" Decode.int)
        (Decode.field "cells" (Decode.list decodeCell))


decodeCell : Decoder { index : Int, richness : Int }
decodeCell =
    Decode.map2 Cell
        (Decode.field "index" Decode.int)
        (Decode.field "richness" Decode.int)


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


{-| Function called during the game loop with the data of the current turn.
-}
turn : TurnData -> GameState -> ( GameState, String, Maybe String )
turn turnData state =
    ( state
    , turnData.possibleActions
        |> List.reverse
        |> List.head
        |> Maybe.withDefault "WAIT"
    , Just <| String.join " " turnData.possibleActions
    )

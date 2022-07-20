module SharedDocumentTests exposing (..)

import Dict exposing (Dict)
import Expect exposing (equal)
import Share
import Test exposing (Test, describe, test)
import Types


test_ label expr expected =
    test label <| \_ -> equal expr expected


doc1 : Types.SharedDocument
doc1 =
    { title = "Test"
    , id = "1"
    , author = Just "jxxcarlson"
    , share = { editors = [ "jxxcarlson", "aristotle" ], readers = [] }
    , currentEditors =
        [ { userId = "j", username = "jxxcarlson", clients = [] }
        , { userId = "a", username = "aristotle", clients = [] }
        ]
    }


doc2 : Types.SharedDocument
doc2 =
    { title = "Test"
    , id = "1"
    , author = Just "jxxcarlson"
    , share = { editors = [ "jxxcarlson", "aristotle" ], readers = [] }
    , currentEditors =
        [ { userId = "a", username = "aristotle", clients = [] }
        ]
    }


shareDocDict1 : Dict String Types.SharedDocument
shareDocDict1 =
    Dict.fromList [ ( "jxxcarslon", doc1 ) ]


shareDocDict2 : Dict String Types.SharedDocument
shareDocDict2 =
    Dict.fromList [ ( "jxxcarslon", doc2 ) ]


suite : Test
suite =
    describe "Share"
        [ test_ "remove user from shared document" (Share.removeUserFromSharedDocument "jxxcarlson" doc1) doc2
        , test_ "remove uuser shared document dict" (Share.removeUserFromSharedDocumentDict "jxxcarlson" shareDocDict1) shareDocDict2
        ]

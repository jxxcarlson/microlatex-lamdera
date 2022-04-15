module Evergreen.V382.Authentication exposing (..)

import Dict
import Evergreen.V382.Credentials
import Evergreen.V382.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V382.User.User
    , credentials : Evergreen.V382.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData

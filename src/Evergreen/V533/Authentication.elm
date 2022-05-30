module Evergreen.V533.Authentication exposing (..)

import Dict
import Evergreen.V533.Credentials
import Evergreen.V533.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V533.User.User
    , credentials : Evergreen.V533.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData

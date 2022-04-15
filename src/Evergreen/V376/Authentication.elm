module Evergreen.V376.Authentication exposing (..)

import Dict
import Evergreen.V376.Credentials
import Evergreen.V376.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V376.User.User
    , credentials : Evergreen.V376.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData

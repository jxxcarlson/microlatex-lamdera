module Evergreen.V418.Authentication exposing (..)

import Dict
import Evergreen.V418.Credentials
import Evergreen.V418.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V418.User.User
    , credentials : Evergreen.V418.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData

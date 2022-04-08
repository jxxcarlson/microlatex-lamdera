module Evergreen.V281.Authentication exposing (..)

import Dict
import Evergreen.V281.Credentials
import Evergreen.V281.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V281.User.User
    , credentials : Evergreen.V281.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData

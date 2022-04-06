module Evergreen.V269.Authentication exposing (..)

import Dict
import Evergreen.V269.Credentials
import Evergreen.V269.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V269.User.User
    , credentials : Evergreen.V269.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData

module View.Input exposing
    ( editors
    , email
    , enterPrivateId
    , group
    , groupAssistant
    , groupMembers
    , groupName
    , password
    , passwordAgain
    , passwordLarge
    , readers
    , realName
    , searchDocsInput
    , searchSourceText
    , searchTagsInput
    , specialInput
    , title
    , username
    , usernameLarge
    )

import Element as E exposing (Element, px)
import Element.Font as Font
import Element.Input as Input
import Types exposing (FrontendModel, FrontendMsg(..))
import View.Utility exposing (onEnter)


searchSourceText : FrontendModel -> Element FrontendMsg
searchSourceText model =
    inputFieldTemplate2 [ onEnter SyncLR |> E.htmlAttribute ] E.fill "Search ..." InputSearchSource model.searchSourceText


enterPrivateId displayText =
    inputFieldTemplate (E.px 200) "Private ID" InputAuthorId displayText


multiLineTemplate : Int -> Int -> String -> (String -> msg) -> String -> Element msg
multiLineTemplate width_ height_ default msg text =
    Input.multiline [ E.moveUp 5, Font.size 16, E.width (E.px width_), E.height (E.px height_) ]
        { onChange = msg
        , text = text
        , label = Input.labelHidden default
        , placeholder = Just <| Input.placeholder [ E.moveUp 5 ] (E.text default)
        , spellcheck = False
        }


readers : Int -> Int -> FrontendModel -> Element FrontendMsg
readers width_ height_ model =
    multiLineTemplate width_ height_ "Readers ..." InputReaders model.inputReaders


editors : Int -> Int -> FrontendModel -> Element FrontendMsg
editors width_ height_ model =
    multiLineTemplate width_ height_ "Editors ..." InputEditors model.inputEditors


inputFieldTemplate : E.Length -> String -> (String -> msg) -> String -> Element msg
inputFieldTemplate width_ default msg text =
    Input.text [ E.moveUp 5, Font.size 16, E.height (px 33), E.width width_ ]
        { onChange = msg
        , text = text
        , label = Input.labelHidden default
        , placeholder = Just <| Input.placeholder [ E.moveUp 5 ] (E.text default)
        }



-- inputFieldTemplate2 :  E.Length -> String -> (String -> msg) -> String -> Element msg


inputFieldTemplate2 attr width_ default msg text =
    Input.text ([ E.moveUp 5, Font.size 16, E.height (px 33), E.width width_ ] ++ attr)
        { onChange = msg
        , text = text
        , label = Input.labelHidden default
        , placeholder = Just <| Input.placeholder [ E.moveUp 5 ] (E.text default)
        }


passwordTemplate : E.Length -> String -> (String -> msg) -> String -> Element msg
passwordTemplate width_ default msg text =
    Input.currentPassword [ E.moveUp 5, Font.size 16, E.height (px 33), E.width width_ ]
        { onChange = msg
        , text = text
        , label = Input.labelHidden default
        , placeholder = Just <| Input.placeholder [ E.moveUp 5 ] (E.text default)
        , show = False
        }


groupMembers : Int -> Int -> FrontendModel -> Element FrontendMsg
groupMembers width_ height_ model =
    multiLineTemplate width_ height_ "Group Members" InputGroupMembers model.inputGroupMembers


groupName : Int -> FrontendModel -> Element FrontendMsg
groupName width_ model =
    inputFieldTemplate (E.px width_) "Group Name" InputGroupName model.inputGroupName


groupAssistant : Int -> FrontendModel -> Element FrontendMsg
groupAssistant width_ model =
    inputFieldTemplate (E.px width_) "Group Assistant" InputGroupAssistant model.inputGroupAssistant


searchDocsInput : FrontendModel -> Element FrontendMsg
searchDocsInput model =
    inputFieldTemplate2 [ onEnter Search |> E.htmlAttribute ] E.fill "Search for documents ..." InputSearchKey model.inputSearchKey


searchTagsInput : FrontendModel -> Element FrontendMsg
searchTagsInput model =
    inputFieldTemplate2 [] E.fill "Filter tags ..." InputSearchTagsKey model.inputSearchTagsKey


username model =
    inputFieldTemplate (E.px 120) "Username" InputUsername model.inputUsername


title model =
    inputFieldTemplate (E.px 500) "Title" InputTitle model.inputTitle


signUpInputWidth =
    220


usernameLarge model =
    inputFieldTemplate (E.px signUpInputWidth) "Username" InputUsername model.inputUsername


realName model =
    inputFieldTemplate (E.px signUpInputWidth) "Real name" InputRealname model.inputRealname


group model =
    inputFieldTemplate (E.px 280) "Group" InputChoseGroup model.inputGroup


email model =
    inputFieldTemplate (E.px signUpInputWidth) "Email" InputEmail model.inputEmail


passwordAgain model =
    passwordTemplate (E.px signUpInputWidth) "Password again" InputPasswordAgain model.inputPasswordAgain


specialInput model =
    inputFieldTemplate (E.px 120) "Special" InputSpecial model.inputSpecial


password model =
    passwordTemplate (E.px 120) "Password" InputPassword model.inputPassword


passwordLarge model =
    passwordTemplate (E.px signUpInputWidth) "Password" InputPassword model.inputPassword

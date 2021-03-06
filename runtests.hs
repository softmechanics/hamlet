{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
import Test.Framework (defaultMain, testGroup, Test)
import Test.Framework.Providers.HUnit
import Test.HUnit hiding (Test)

import Text.Hamlet
import Text.Cassius
import Text.Julius
import Data.List (intercalate)
import Text.Utf8

main :: IO ()
main = defaultMain [testSuite]

testSuite :: Test
testSuite = testGroup "Text.Hamlet"
    [ testCase "empty" caseEmpty
    , testCase "static" caseStatic
    , testCase "tag" caseTag
    , testCase "var" caseVar
    , testCase "var chain " caseVarChain
    , testCase "url" caseUrl
    , testCase "url chain " caseUrlChain
    , testCase "embed" caseEmbed
    , testCase "embed chain " caseEmbedChain
    , testCase "if" caseIf
    , testCase "if chain " caseIfChain
    , testCase "else" caseElse
    , testCase "else chain " caseElseChain
    , testCase "elseif" caseElseIf
    , testCase "elseif chain " caseElseIfChain
    , testCase "list" caseList
    , testCase "list chain" caseListChain
    , testCase "script not empty" caseScriptNotEmpty
    , testCase "meta empty" caseMetaEmpty
    , testCase "input empty" caseInputEmpty
    , testCase "multiple classes" caseMultiClass
    , testCase "attrib order" caseAttribOrder
    , testCase "nothing" caseNothing
    , testCase "nothing chain " caseNothingChain
    , testCase "just" caseJust
    , testCase "just chain " caseJustChain
    , testCase "constructor" caseConstructor
    , testCase "url + params" caseUrlParams
    , testCase "escape" caseEscape
    , testCase "empty statement list" caseEmptyStatementList
    , testCase "attribute conditionals" caseAttribCond
    , testCase "non-ascii" caseNonAscii
    , testCase "maybe function" caseMaybeFunction
    , testCase "trailing dollar sign" caseTrailingDollarSign
    , testCase "non leading percent sign" caseNonLeadingPercent
    , testCase "quoted attributes" caseQuotedAttribs
    , testCase "spaced derefs" caseSpacedDerefs
    , testCase "attrib vars" caseAttribVars
    , testCase "strings and html" caseStringsAndHtml
    , testCase "nesting" caseNesting
    , testCase "trailing space" caseTrailingSpace
    , testCase "currency symbols" caseCurrency
    , testCase "external" caseExternal
    , testCase "parens" caseParens
    , testCase "hamlet literals"caseHamletLiterals
    , testCase "hamlet' and xhamlet'" caseHamlet'
    , testCase "hamletDebug" caseHamletDebug
    , testCase "hamlet runtime" caseHamletRT
    , testCase "hamletFileDebug- changing file" caseHamletFileDebugChange
    , testCase "hamletFileDebug- features" caseHamletFileDebugFeatures
    , testCase "cassius" caseCassius
    , testCase "cassiusFile" caseCassiusFile
    , testCase "cassiusFileDebug" caseCassiusFileDebug
    , testCase "cassiusFileDebugChange" caseCassiusFileDebugChange
    , testCase "julius" caseJulius
    , testCase "juliusFile" caseJuliusFile
    , testCase "juliusFileDebug" caseJuliusFileDebug
    , testCase "juliusFileDebugChange" caseJuliusFileDebugChange
    , testCase "comments" caseComments
    , testCase "hamletFileDebug double foralls" caseDoubleForalls
    , testCase "cassius pseudo-class" casePseudo
    , testCase "different binding names" caseDiffBindNames
    , testCase "blank line" caseBlankLine
    , testCase "leading spaces" caseLeadingSpaces
    ]

data Url = Home | Sub SubUrl
data SubUrl = SubUrl
render :: Url -> [(String, String)] -> String
render Home qs = "url" ++ showParams qs
render (Sub SubUrl) qs = "suburl" ++ showParams qs

showParams :: [(String, String)] -> String
showParams [] = ""
showParams z =
    '?' : intercalate "&" (map go z)
  where
    go (x, y) = go' x ++ '=' : go' y
    go' = concatMap encodeUrlChar

-- | Taken straight from web-encodings; reimplemented here to avoid extra
-- dependencies.
encodeUrlChar :: Char -> String
encodeUrlChar c
    -- List of unreserved characters per RFC 3986
    -- Gleaned from http://en.wikipedia.org/wiki/Percent-encoding
    | 'A' <= c && c <= 'Z' = [c]
    | 'a' <= c && c <= 'z' = [c]
    | '0' <= c && c <= '9' = [c]
encodeUrlChar c@'-' = [c]
encodeUrlChar c@'_' = [c]
encodeUrlChar c@'.' = [c]
encodeUrlChar c@'~' = [c]
encodeUrlChar ' ' = "+"
encodeUrlChar y =
    let (a, c) = fromEnum y `divMod` 16
        b = a `mod` 16
        showHex' x
            | x < 10 = toEnum $ x + (fromEnum '0')
            | x < 16 = toEnum $ x - 10 + (fromEnum 'A')
            | otherwise = error $ "Invalid argument to showHex: " ++ show x
     in ['%', showHex' b, showHex' c]

data Arg url = Arg
    { getArg :: Arg url
    , var :: Html
    , url :: Url
    , embed :: Hamlet url
    , true :: Bool
    , false :: Bool
    , list :: [Arg url]
    , nothing :: Maybe String
    , just :: Maybe String
    , urlParams :: (Url, [(String, String)])
    }

theArg :: Arg url
theArg = Arg
    { getArg = theArg
    , var = string "<var>"
    , url = Home
    , embed = [$hamlet|embed|]
    , true = True
    , false = False
    , list = [theArg, theArg, theArg]
    , nothing = Nothing
    , just = Just "just"
    , urlParams = (Home, [("foo", "bar"), ("foo1", "bar1")])
    }

helper :: String -> Hamlet Url -> Assertion
helper res h = do
    let x = renderHamlet render h
    res @=? lbsToChars x

caseEmpty :: Assertion
caseEmpty = helper "" [$hamlet||]

caseStatic :: Assertion
caseStatic = helper "some static content" [$hamlet|some static content|]

caseTag :: Assertion
caseTag = helper "<p class=\"foo\"><div id=\"bar\">baz</div></p>" [$hamlet|
%p.foo
 #bar baz|]

caseVar :: Assertion
caseVar = do
    helper "&lt;var&gt;" [$hamlet|$var.theArg$|]

caseVarChain :: Assertion
caseVarChain = do
    helper "&lt;var&gt;" [$hamlet|$var.getArg.getArg.getArg.theArg$|]

caseUrl :: Assertion
caseUrl = do
    helper (render Home []) [$hamlet|@url.theArg@|]

caseUrlChain :: Assertion
caseUrlChain = do
    helper (render Home []) [$hamlet|@url.getArg.getArg.getArg.theArg@|]

caseEmbed :: Assertion
caseEmbed = do
    helper "embed" [$hamlet|^embed.theArg^|]

caseEmbedChain :: Assertion
caseEmbedChain = do
    helper "embed" [$hamlet|^embed.getArg.getArg.getArg.theArg^|]

caseIf :: Assertion
caseIf = do
    helper "if" [$hamlet|
$if true.theArg
    if
|]

caseIfChain :: Assertion
caseIfChain = do
    helper "if" [$hamlet|
$if true.getArg.getArg.getArg.theArg
    if
|]

caseElse :: Assertion
caseElse = helper "else" [$hamlet|
$if false.theArg
    if
$else
    else
|]

caseElseChain :: Assertion
caseElseChain = helper "else" [$hamlet|
$if false.getArg.getArg.getArg.theArg
    if
$else
    else
|]

caseElseIf :: Assertion
caseElseIf = helper "elseif" [$hamlet|
$if false.theArg
    if
$elseif true.theArg
    elseif
$else
    else
|]

caseElseIfChain :: Assertion
caseElseIfChain = helper "elseif" [$hamlet|
$if false.getArg.getArg.getArg.theArg
    if
$elseif true.getArg.getArg.getArg.theArg
    elseif
$else
    else
|]

caseList :: Assertion
caseList = do
    helper "xxx" [$hamlet|
$forall list.theArg _x
    x
|]

caseListChain :: Assertion
caseListChain = do
    helper "urlurlurl" [$hamlet|
$forall list.getArg.getArg.getArg.getArg.getArg.theArg x
    @url.x@
|]

caseScriptNotEmpty :: Assertion
caseScriptNotEmpty = helper "<script></script>" [$hamlet|%script|]

caseMetaEmpty :: Assertion
caseMetaEmpty = do
    helper "<meta>" [$hamlet|%meta|]
    helper "<meta/>" [$xhamlet|%meta|]

caseInputEmpty :: Assertion
caseInputEmpty = do
    helper "<input>" [$hamlet|%input|]
    helper "<input/>" [$xhamlet|%input|]

caseMultiClass :: Assertion
caseMultiClass = do
    helper "<div class=\"foo bar\"></div>" [$hamlet|.foo.bar|]

caseAttribOrder :: Assertion
caseAttribOrder = helper "<meta 1 2 3>" [$hamlet|%meta!1!2!3|]

caseNothing :: Assertion
caseNothing = do
    helper "" [$hamlet|
$maybe nothing.theArg _n
    nothing
|]
    helper "nothing" [$hamlet|
$maybe nothing.theArg _n
    something
$nothing
    nothing
|]

caseNothingChain :: Assertion
caseNothingChain = helper "" [$hamlet|
$maybe nothing.getArg.getArg.getArg.theArg n
    nothing $n$
|]

caseJust :: Assertion
caseJust = helper "it's just" [$hamlet|
$maybe just.theArg n
    it's $n$
|]

caseJustChain :: Assertion
caseJustChain = helper "it's just" [$hamlet|
$maybe just.getArg.getArg.getArg.theArg n
    it's $n$
|]

caseConstructor :: Assertion
caseConstructor = do
    helper "url" [$hamlet|@Home@|]
    helper "suburl" [$hamlet|@Sub.SubUrl@|]
    let text = "<raw text>"
    helper "<raw text>" [$hamlet|$preEscapedString.text$|]

caseUrlParams :: Assertion
caseUrlParams = do
    helper "url?foo=bar&amp;foo1=bar1" [$hamlet|@?urlParams.theArg@|]

caseEscape :: Assertion
caseEscape = do
    helper "#this is raw\n " [$hamlet|
\#this is raw
\
\ 
|]
    helper "$@^" [$hamlet|$$@@^^|]

caseEmptyStatementList :: Assertion
caseEmptyStatementList = do
    helper "" [$hamlet|$if True|]
    helper "" [$hamlet|$maybe Nothing _x|]
    let emptyList = []
    helper "" [$hamlet|$forall emptyList _x|]

caseAttribCond :: Assertion
caseAttribCond = do
    helper "<select></select>" [$hamlet|%select!:False:selected|]
    helper "<select selected></select>" [$hamlet|%select!:True:selected|]
    helper "<meta var=\"foo:bar\">" [$hamlet|%meta!var=foo:bar|]
    helper "<select selected></select>"
        [$hamlet|%select!:true.theArg:selected|]

caseNonAscii :: Assertion
caseNonAscii = do
    helper "עִבְרִי" [$hamlet|עִבְרִי|]

caseMaybeFunction :: Assertion
caseMaybeFunction = do
    helper "url?foo=bar&amp;foo1=bar1" [$hamlet|
$maybe Just.urlParams x
    @?x.theArg@
|]

caseTrailingDollarSign :: Assertion
caseTrailingDollarSign =
    helper "trailing space \ndollar sign $" [$hamlet|trailing space $
\
dollar sign $$|]

caseNonLeadingPercent :: Assertion
caseNonLeadingPercent =
    helper "<span style=\"height:100%\">foo</span>" [$hamlet|
%span!style=height:100% foo
|]

caseQuotedAttribs :: Assertion
caseQuotedAttribs =
    helper "<input type=\"submit\" value=\"Submit response\">" [$hamlet|
%input!type=submit!value="Submit response"
|]

caseSpacedDerefs :: Assertion
caseSpacedDerefs = do
    helper "&lt;var&gt;" [$hamlet|$var theArg$|]
    helper "<div class=\"&lt;var&gt;\"></div>" [$hamlet|.$var theArg$|]

caseAttribVars :: Assertion
caseAttribVars = do
    helper "<div id=\"&lt;var&gt;\"></div>" [$hamlet|#$var.theArg$|]
    helper "<div class=\"&lt;var&gt;\"></div>" [$hamlet|.$var.theArg$|]
    helper "<div f=\"&lt;var&gt;\"></div>" [$hamlet|!f=$var.theArg$|]

caseStringsAndHtml :: Assertion
caseStringsAndHtml = do
    let str = "<string>"
    let html = preEscapedString "<html>"
    helper "&lt;string&gt; <html>" [$hamlet|$str$ $html$|]

caseNesting :: Assertion
caseNesting = do
    helper
      "<table><tbody><tr><td>1</td></tr><tr><td>2</td></tr></tbody></table>"
      [$hamlet|
%table
  %tbody
    $forall users user
        %tr
         %td $user$
|]
    helper
        (concat
          [ "<select id=\"foo\" name=\"foo\"><option selected></option>"
          , "<option value=\"true\">Yes</option>"
          , "<option value=\"false\">No</option>"
          , "</select>"
          ])
        [$hamlet|
%select#$name$!name=$name$
    %option!:isBoolBlank.val:selected
    %option!value=true!:isBoolTrue.val:selected Yes
    %option!value=false!:isBoolFalse.val:selected No
|]
  where
    users = ["1", "2"]
    name = "foo"
    val = 5 :: Int
    isBoolBlank _ = True
    isBoolTrue _ = False
    isBoolFalse _ = False

caseTrailingSpace :: Assertion
caseTrailingSpace =
    helper "" [$hamlet|        |]

caseCurrency :: Assertion
caseCurrency =
    helper foo [$hamlet|$foo$|]
  where
    foo = "eg: 5, $6, €7.01, £75"

caseExternal :: Assertion
caseExternal = do
    helper "foo<br>" $ $(hamletFile "external.hamlet")
    helper "foo<br/>" $ $(xhamletFile "external.hamlet")
  where
    foo = "foo"

caseParens :: Assertion
caseParens = do
    let plus = (++)
        x = "x"
        y = "y"
    helper "xy" [$hamlet|$(plus x) y$|]
    helper "xy" [$hamlet|$(plus.x).y$|]
    helper "xxy" [$hamlet|$(plus (plus x).x).y$|]
    let alist = ["1", "2", "3"]
    helper "123" [$hamlet|
$forall (id id.id id.alist) x
    $x$
|]

caseHamletLiterals :: Assertion
caseHamletLiterals = helper "123" [$hamlet|$show.123$|]

helper' :: String -> Html -> Assertion
helper' res h = do
    let x = renderHtml h
    res @=? lbsToChars x

caseHamlet' :: Assertion
caseHamlet' = do
    helper' "foo" [$hamlet'|foo|]
    helper' "foo" [$xhamlet'|foo|]
    helper "<br>" $ const $ [$hamlet'|%br|]
    helper "<br/>" $ const $ [$xhamlet'|%br|]

    -- new with generalized stuff
    helper' "foo" [$hamlet|foo|]
    helper' "foo" [$xhamlet|foo|]
    helper "<br>" $ const $ [$hamlet|%br|]
    helper "<br/>" $ const $ [$xhamlet|%br|]

caseHamletDebug :: Assertion
caseHamletDebug = do
    helper "<p>foo</p>\n<p>bar</p>\n" [$hamletDebug|
%p foo
%p bar
|]

caseHamletRT :: Assertion
caseHamletRT = do
    temp <- parseHamletRT defaultHamletSettings "$var$"
    rt <- parseHamletRT defaultHamletSettings $
            unlines
                [ "$baz.bar.foo$ bin $"
                , "$forall list l"
                , "  $l$"
                , "$maybe just j"
                , "  $j$"
                , "$maybe nothing n"
                , "$nothing"
                , "  nothing"
                , "^template^"
                , "@url@"
                , "$if false"
                , "$elseif false"
                , "$elseif true"
                , "  a"
                , "$if false"
                , "$else"
                , "  b"
                , "@?urlp@"
                ]
    let scope =
            [ (["foo", "bar", "baz"], HDHtml $ preEscapedString "foo<bar>baz")
            , (["list"], HDList
                [ [([], HDHtml $ string "1")]
                , [([], HDHtml $ string "2")]
                , [([], HDHtml $ string "3")]
                ])
            , (["just"], HDMaybe $ Just
                [ ([], HDHtml $ string "just")
                ])
            , (["nothing"], HDMaybe Nothing)
            , (["template"], HDTemplate temp)
            , (["var"], HDHtml $ string "var")
            , (["url"], HDUrl Home)
            , (["urlp"], HDUrlParams Home [("foo", "bar")])
            , (["true"], HDBool True)
            , (["false"], HDBool False)
            ]
    rend <- renderHamletRT rt scope render
    lbsToChars (renderHtml rend) @?=
        "foo<bar>baz bin 123justnothingvarurlaburl?foo=bar"

caseHamletFileDebugChange :: Assertion
caseHamletFileDebugChange = do
    let foo = "foo"
    writeFile "external-debug.hamlet" "$foo$ 1"
    helper "foo 1" $ $(hamletFileDebug "external-debug.hamlet")
    writeFile "external-debug.hamlet" "$foo$ 2"
    helper "foo 2" $ $(hamletFileDebug "external-debug.hamlet")
    writeFile "external-debug.hamlet" "$foo$ 1"

caseHamletFileDebugFeatures :: Assertion
caseHamletFileDebugFeatures = do
    let var = "var"
    let url = Home
    let urlp = (Home, [("foo", "bar")])
    let template = [$hamlet|template|]
    let true = True
    let just = Just "just"
        nothing = Nothing
    let list = words "1 2 3"
    let extra = "e"
    flip helper $(hamletFileDebug "external-debug2.hamlet") $ concat
        [ "var"
        , "var"
        , "url"
        , "url"
        , "suburl"
        , "url?foo=bar"
        , "template"
        , "truee"
        , "not truee"
        , "elseif truee"
        , "just"
        , "juste"
        , "nothinge"
        , "1e2e3e"
        ]

celper :: String -> Cassius Url -> Assertion
celper res h = do
    let x = renderCassius render h
    res @=? lbsToChars x

mixin :: CassiusMixin a
mixin = [$cassiusMixin|
a: b
c: d
|]

caseCassius :: Assertion
caseCassius = do
    let var = "var"
    let urlp = (Home, [("p", "q")])
    flip celper [$cassius|
foo
    color: $colorRed$
    background: $colorBlack$
    bar: baz
    bin
        color: $(((Color 127) 100) 5)$
        bar: bar
        unicode-test: שלום
        f$var$x: someval
        background-image: url(@Home@)
        urlp: url(@?urlp@)
    ^mixin^
|] $ concat
        [ "foo{color:#F00;background:#000;bar:baz;a:b;c:d}"
        , "foo bin{color:#7F6405;bar:bar;unicode-test:שלום;fvarx:someval;"
        , "background-image:url(url);urlp:url(url?p=q)}"
        ]

caseCassiusFile :: Assertion
caseCassiusFile = do
    let var = "var"
    let urlp = (Home, [("p", "q")])
    flip celper $(cassiusFile "external1.cassius") $ concat
        [ "foo{color:#F00;background:#000;bar:baz;a:b;c:d}"
        , "foo bin{color:#7F6405;bar:bar;unicode-test:שלום;fvarx:someval;"
        , "background-image:url(url);urlp:url(url?p=q)}"
        ]

caseCassiusFileDebug :: Assertion
caseCassiusFileDebug = do
    let var = "var"
    let urlp = (Home, [("p", "q")])
    flip celper $(cassiusFileDebug "external1.cassius") $ concat
        [ "foo{color:#F00;background:#000;bar:baz;a:b;c:d}"
        , "foo bin{color:#7F6405;bar:bar;unicode-test:שלום;fvarx:someval;"
        , "background-image:url(url);urlp:url(url?p=q)}"
        ]

caseCassiusFileDebugChange :: Assertion
caseCassiusFileDebugChange = do
    let var = "var"
    writeFile "external2.cassius" "foo\n  $var$: 1"
    celper "foo{var:1}" $(cassiusFileDebug "external2.cassius")
    writeFile "external2.cassius" "foo\n  $var$: 2"
    celper "foo{var:2}" $(cassiusFileDebug "external2.cassius")
    writeFile "external2.cassius" "foo\n  $var$: 1"

jmixin = [$julius|var x;|]

jelper :: String -> Julius Url -> Assertion
jelper res h = do
    let x = renderJulius render h
    res @=? lbsToChars x

caseJulius :: Assertion
caseJulius = do
    let var = "var"
    let urlp = (Home, [("p", "q")])
    flip jelper [$julius|שלום
%var%
@Home@
@?urlp@
^jmixin^
|] $ intercalate "\r\n"
        [ "שלום"
        , var
        , "url"
        , "url?p=q"
        , "var x;"
        ] ++ "\r\n"

caseJuliusFile :: Assertion
caseJuliusFile = do
    let var = "var"
    let urlp = (Home, [("p", "q")])
    flip jelper $(juliusFile "external1.julius") $ unlines
        [ "שלום"
        , var
        , "url"
        , "url?p=q"
        , "var x;"
        ]

caseJuliusFileDebug :: Assertion
caseJuliusFileDebug = do
    let var = "var"
    let urlp = (Home, [("p", "q")])
    flip jelper $(juliusFileDebug "external1.julius") $ unlines
        [ "שלום"
        , var
        , "url"
        , "url?p=q"
        , "var x;"
        ]

caseJuliusFileDebugChange :: Assertion
caseJuliusFileDebugChange = do
    let var = "somevar"
    writeFile "external2.julius" "var %var% = 1;"
    jelper "var somevar = 1;" $(juliusFileDebug "external2.julius")
    writeFile "external2.julius" "var %var% = 2;"
    jelper "var somevar = 2;" $(juliusFileDebug "external2.julius")
    writeFile "external2.julius" "var %var% = 1;"

caseComments :: Assertion
caseComments = do
    helper "" [$hamlet|$# this is a comment
$# another comment
$#a third one|]
    celper "" [$cassius|$# this is a comment
$# another comment
$#a third one|]

caseDoubleForalls :: Assertion
caseDoubleForalls = do
    let list = map show [1..2]
    helper "12" $(hamletFileDebug "double-foralls.hamlet")
instance Show Url where
    show _ = "FIXME remove this instance show Url"

casePseudo :: Assertion
casePseudo = do
    flip celper [$cassius|
a:visited
    color: blue
|] "a:visited{color:blue}"

caseDiffBindNames :: Assertion
caseDiffBindNames = do
    let list = words "1 2 3"
    -- FIXME helper "123123" $(hamletFileDebug "external-debug3.hamlet")
    error "test has been disabled"

caseBlankLine :: Assertion
caseBlankLine = do
    helper "<p>foo</p>" [$hamlet|
%p

    foo
|]
    celper "foo{bar:baz}" [$cassius|
foo

    bar: baz
|]

caseLeadingSpaces :: Assertion
caseLeadingSpaces =
    celper "foo{bar:baz}" [$cassius|
  foo
    bar: baz
|]

caseTrailingSpaces :: Assertion
caseTrailingSpaces = helper "" [$hamlet|
$if   True   
$elseif   False   
$else   
$maybe Nothing   x 
$nothing  
$forall   empty    x   
|]
  where
    empty = []

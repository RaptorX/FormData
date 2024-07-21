# FormData v1.0.0

## Represents form data to be sent via HTTP

This class allows for the construction of multipart/form-data bodies,
commonly used for file uploads and submitting forms with complex data.

---

## Instance Properties

- `String`      contentType - The Content-Type header for the form data.
- `String`      boundary    - The boundary string used to separate the parts of the form data.
- `ComObjArray` data        - The binary representation of the form data to be sent via the body of an HTTP request.

---

## Methods

- `__New(data)` - Creates a new FormData object handling binary files for HTTP requests.

---

## Example

```ahk

       parts := {
               token: '3c2e0e0119165134127ca631e551c5f8',
               upload_session: A_Now,
               numfiles: 1,
               gallery: false,
               adult: false,
               ui: false,
               optsize: false,
               upload_referer: 'https://postimages.org',
               mode: false,
               lang: false,
               content: false,
               forumurl: false,
               file: ['D:\Cloud\RaptorX\OneDrive\Pictures\Anime\37.jpg']
       }

       form := FormData(parts)

       http := ComObject('WinHttp.WinHttpRequest.5.1')

       http.Open('POST', 'https://postimg.cc/json?q=a')
       http.SetRequestHeader('Content-Type', form.contentType)
       http.Option(EnableRedirects:=6)

       http.Send(form.body)

       OutputDebug http.Status '`n'
       OutputDebug http.GetAllResponseHeaders() '`n'
       OutputDebug http.ResponseText '`n'

```

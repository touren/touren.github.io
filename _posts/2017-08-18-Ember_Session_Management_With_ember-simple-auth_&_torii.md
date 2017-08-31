---
layout: post
title: Ember Session Management With ember-simple-auth & torii.
description: How to manage account session (Authentication/Authorization), e.g. sign-up, login, oauth-login, logout, by ember-simple-auth & torii.
tags: 
    - ember
    - session management
    - authentication
    - authorization
    - ember-simple-auth
    - torii
---

## What is session management
Most of the web app will have such features: 
* Sign up: Create a new account in current system, usually by email.
* Login: Use the account just created to log in, session starts.
* Sign in: Use oauth service to log in without createing a new account, session starts too.

    ![signin_pic]
* Logout/Sign out: Log out current account, session ends.

All of above can be handled by Ember library [ember-simple-auth], combined with [torii].

I will explain how to do that by an example Ember App.

## Installation
```
ember install ember-simple-auth
ember install torii
```

## Walkthrough

Once the libraries are installed, the session service can be injected wherever needed in the application. In order to display login/logout buttons depending on the current session state, inject the service into the respective controller or component and query its [`isAuthenticated` property][isAuthenticated] in the template:

```javascript
// app/pods/application/route.js
import Ember from 'ember';

export default Ember.Controller.extend({
  session: Ember.inject.service('session')
  …
  actions: {
    invalidateSession() {
      this.get('session').invalidate();
    }
  }  
});
```

```hbs
{{!-- app/pods/application/templates.hbs --}}
<div class="menu">
  ……
  {{#if session.isAuthenticated}}
    <a {{action 'invalidateSession'}}>Logout</a>
  {{else}}
    {{#link-to 'login'}}Login{{/link-to}}
  {{/if}}
</div>
<div class="main">
  {{outlet}}
</div>
```

In the `invalidateSession` action call the [session service's `invalidate` method][invalidate] to invalidate the session and log the user out:

For authenticating the session, the session service provides the [`authenticate` method] that takes the name of the authenticator to use as well as other arguments depending on specific authenticator used. To define an authenticator, add a new file in app/authenticators and extend one of the authenticators the library comes with, e.g.:

```javascript
// app/authenticators/oauth2.js
import OAuth2PasswordGrant from 'ember-simple-auth/authenticators/oauth2-password-grant';

export default OAuth2PasswordGrant.extend();
```

With that authenticator and a login form like
```hbs
{{!-- app/pods/login/templates.hbs --}}
<form {{action 'authenticate' on='submit'}}>
  <label for="identification">Login</label>
  {{input id='identification' placeholder='Enter Login' value=identification}}
  <label for="password">Password</label>
  {{input id='password' placeholder='Enter Password' type='password' value=password}}
  <button type="submit">Login</button>
  {{#if errorMessage}}
    <p>{{errorMessage}}</p>
  {{/if}}
</form>
```

the session can be authenticated with the session service's [`authenticate` method]:

```javascript
// app/pods/login/route.js
import Ember from 'ember';

export default Ember.Controller.extend({
  session: Ember.inject.service('session'),

  actions: {
    authenticate() {
      let { identification, password } = this.getProperties('identification', 'password');
      this.get('session').authenticate('authenticator:oauth2', identification, password).then(() => {
        this.afterLoginOK();
      }).catch((reason) => {
        this.set('errorMessage', reason.error || reason);
      });
    }
  }
});
```

That's for login with username and passowrd (i.e. account of current system). How about oauth sign-in, e.g. Google Sign-in? It's time for [torii] kicking in. Create a torii authenticator in app/authenticators.
```javascript
// app/authenticators/torii.js
import ToriiAuthenticator from 'ember-simple-auth/authenticators/torii';

export default ToriiAuthenticator.extend({
  torii: Ember.inject.service(),
});
```

```hbs
{{!-- app/pods/login/templates.hbs --}}
……
<a class="button" {{action 'googleSignIn'}}> GOOGLE SIGN IN </a>
```

```javascript
// app/pods/login/route.js
……
  actions: {
      googleSignIn() {
        this.get('session').authenticate('authenticator:torii', "google-oauth2").then( () => {
          this.afterLoginOK();
        }).catch( (err) => {
          this.set('errorMessage', reason.error || reason);
        });
      }
……
```

In above action method `googleSignIn`, the [`authenticate` method] will pop up a Google Sign-in consent screen to do the authentication. What a magic, it's because `google-oauth2` is a [build-in provider] within [torii] library.

![google_signin_pic]

Wait a minute, how about the client ID and redirect URI, which are essential for an OAuth authentication, according to [Google's Sign-in Guildline].

## Reference
* [ember-simple-auth]
* [torii]




[//]: # (Some links will be used in current post.)
[signin_pic]: /assets/images/ember_session_management/image_01.png "oauth sign-in"
[google_signin_pic]: /assets/images/ember_session_management/image_02.png "google sign-in"
[ember-simple-auth]: https://github.com/simplabs/ember-simple-auth
[torii]: https://github.com/Vestorly/torii
[isAuthenticated]: http://ember-simple-auth.com/api/classes/SessionService.html#property_isAuthenticated
[invalidate]: http://ember-simple-auth.com/api/classes/SessionService.html#method_invalidate
[`authenticate` method]: http://ember-simple-auth.com/api/classes/SessionService.html#method_authenticate
[authenticate]: http://ember-simple-auth.com/api/classes/SessionService.html#method_authenticate
[build-in provider]: https://github.com/Vestorly/torii#built-in-providers
[Google's Sign-in Guildline]: https://developers.google.com/identity/sign-in/web/server-side-flow
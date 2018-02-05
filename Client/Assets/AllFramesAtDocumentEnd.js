!function(e){var n={};function t(r){if(n[r])return n[r].exports;var i=n[r]={i:r,l:!1,exports:{}};return e[r].call(i.exports,i,i.exports,t),i.l=!0,i.exports}t.m=e,t.c=n,t.d=function(e,n,r){t.o(e,n)||Object.defineProperty(e,n,{configurable:!1,enumerable:!0,get:r})},t.n=function(e){var n=e&&e.__esModule?function(){return e.default}:function(){return e};return t.d(n,"a",n),n},t.o=function(e,n){return Object.prototype.hasOwnProperty.call(e,n)},t.p="",t(t.s=5)}([,,,,,function(e,n,t){t(6),t(7),t(8),e.exports=t(9)},function(e,n,t){"use strict";window.__firefox__||Object.defineProperty(window,"__firefox__",{enumerable:!1,configurable:!1,writable:!1,value:{userScripts:{},includeOnce:function(e){return!!__firefox__.userScripts[e]||(__firefox__.userScripts[e]=!0,!1)}}})},function(e,n,t){"use strict";window.__firefox__.includeOnce("ContextMenu")||window.addEventListener("touchstart",function(e){var n=e.target,t=n.closest("a"),r=n.closest("img");if(t||r){var i={};t&&(i.link=t.href),r&&(i.image=r.src),(i.link||i.image)&&webkit.messageHandlers.contextMenuMessageHandler.postMessage(i)}},!0)},function(e,n,t){"use strict";var r=function(){return function(e,n){if(Array.isArray(e))return e;if(Symbol.iterator in Object(e))return function(e,n){var t=[],r=!0,i=!1,o=void 0;try{for(var s,a=e[Symbol.iterator]();!(r=(s=a.next()).done)&&(t.push(s.value),!n||t.length!==n);r=!0);}catch(e){i=!0,o=e}finally{try{!r&&a.return&&a.return()}finally{if(i)throw o}}return t}(e,n);throw new TypeError("Invalid attempt to destructure non-iterable instance")}}();!function(){if(!window.__firefox__.includeOnce("LoginsHelper")){var e=!1,n={_getRandomId:function(){return Math.round(Math.random()*(Number.MAX_VALUE-Number.MIN_VALUE)+Number.MIN_VALUE).toString()},_messages:["RemoteLogins:loginsFound"],_requests:{},_takeRequest:function(e){var n=e,t=this._requests[n.requestId];return this._requests[n.requestId]=void 0,t},_sendRequest:function(e,n){var t=this._getRandomId();n.requestId=t,webkit.messageHandlers.loginsManagerMessageHandler.postMessage(n);var r=this;return new Promise(function(n,i){e.promise={resolve:n,reject:i},r._requests[t]=e})},receiveMessage:function(e){var n=this._takeRequest(e);switch(e.name){case"RemoteLogins:loginsFound":n.promise.resolve({form:n.form,loginsFound:e.logins});break;case"RemoteLogins:loginsAutoCompleted":n.promise.resolve(e.logins)}},_asyncFindLogins:function(e,n){var r=this._getFormFields(e,!1);if(!r[0]||!r[1])return Promise.reject("No logins found");r[0].addEventListener("blur",s);var i=t._getPasswordOrigin(),o=t._getActionOrigin(e);if(null==o)return Promise.reject("Action origin is null");var a={form:e},l={type:"request",formOrigin:i,actionOrigin:o};return this._sendRequest(a,l)},loginsFound:function(e,n){this._fillForm(e,!0,!1,!1,!1,n)},onUsernameInput:function(e){var n=e.target;if(n.ownerDocument instanceof HTMLDocument&&this._isUsernameFieldType(n)){var t=n.form;if(t&&n.value){o("onUsernameInput from",e.type);var i=this._getFormFields(t,!1),s=r(i,3),a=s[0],l=s[1];s[2];if(a==n&&l){var u=this;this._asyncFindLogins(t,{showMasterPassword:!1}).then(function(e){u._fillForm(e.form,!0,!0,!0,!0,e.loginsFound)}).then(null,o)}}}},_getPasswordFields:function(e,n){for(var t=[],r=0;r<e.elements.length;r++){var i=e.elements[r];i instanceof HTMLInputElement&&"password"==i.type&&(n&&!i.value||(t[t.length]={index:r,element:i}))}return 0==t.length?(o("(form ignored -- no password fields.)"),null):t.length>3?(o("(form ignored -- too many password fields. [ got ",t.length),null):t},_isUsernameFieldType:function(e){if(!(e instanceof HTMLInputElement))return!1;var n=e.hasAttribute("type")?e.getAttribute("type").toLowerCase():e.type;return"text"==n||"email"==n||"url"==n||"tel"==n||"number"==n},_getFormFields:function(e,n){var t,r,i=null,s=this._getPasswordFields(e,n);if(!s)return[null,null,null];for(var a=s[0].index-1;a>=0;a--){var l=e.elements[a];if(this._isUsernameFieldType(l)){i=l;break}}if(i||o("(form -- no username field found)"),!n||1==s.length)return[i,s[0].element,null];var u=s[0].element.value,f=s[1].element.value,d=s[2]?s[2].element.value:null;if(3==s.length)if(u==f&&f==d)r=s[0].element,t=null;else if(u==f)r=s[0].element,t=s[2].element;else if(f==d)t=s[0].element,r=s[2].element;else{if(u!=d)return o("(form ignored -- all 3 pw fields differ)"),[null,null,null];r=s[0].element,t=s[1].element}else u==f?(r=s[0].element,t=null):(t=s[0].element,r=s[1].element);return[i,r,t]},_isAutocompleteDisabled:function(e){return!(!e||!e.hasAttribute("autocomplete")||"off"!=e.getAttribute("autocomplete").toLowerCase())},_onFormSubmit:function(e){var n=e.ownerDocument,r=n.defaultView;var i=t._getPasswordOrigin(n.documentURI);if(i){var s=t._getActionOrigin(e),a=this._getFormFields(e,!0),l=a[0],u=a[1],f=a[2];if(null!=u){this._isAutocompleteDisabled(e)||this._isAutocompleteDisabled(l)||this._isAutocompleteDisabled(u)||this._isAutocompleteDisabled(f),0;var d=l?{name:l.name,value:l.value}:null,m={name:u.name,value:u.value};f&&(f.name,f.value),r.opener&&r.opener.top;webkit.messageHandlers.loginsManagerMessageHandler.postMessage({type:"submit",hostname:i,username:d.value,usernameField:d.name,password:m.value,passwordField:m.name,formSubmitURL:s})}}else o("(form submission ignored -- invalid hostname)")},_fillForm:function(e,n,t,r,i,s){var a=this._getFormFields(e,!1),l=a[0],f=a[1];if(null==f)return[!1,s];if(f.disabled||f.readOnly)return o("not filling form, password field disabled or read-only"),[!1,s];var d=Number.MAX_VALUE,m=Number.MAX_VALUE;l&&l.maxLength>=0&&(d=l.maxLength),f.maxLength>=0&&(m=f.maxLength);var c=(s=function(e,n){var t,r,i;if(null==e)throw new TypeError("Array is null or not defined");var o=Object(e),s=o.length>>>0;if("function"!=typeof n)throw new TypeError(n+" is not a function");arguments.length>1&&(t=e);r=new Array(s),i=0;for(;i<s;){var a,l;i in o&&(a=o[i],l=n.call(t,a,i,o),r[i]=l),i++}return r}(s,function(e){return{hostname:e.hostname,formSubmitURL:e.formSubmitURL,httpReal:e.httpRealm,username:e.username,password:e.password,usernameField:e.usernameField,passwordField:e.passwordField}})).filter(function(e){var n=e.username.length<=d&&e.password.length<=m;return n||o("Ignored",e.username),n},this);if(0==c.length)return[!1,s];if(f.value&&!r)return"existingPassword",[!1,s];var g=!1;!t&&(this._isAutocompleteDisabled(e)||this._isAutocompleteDisabled(l)||this._isAutocompleteDisabled(f))&&(g=!0,o("form not filled, has autocomplete=off"));var v=null;if(l&&(l.value||l.disabled||l.readOnly)){var h=l.value.toLowerCase();if((w=c.filter(function(e){return e.username.toLowerCase()==h})).length){for(var p=0;p<w.length;p++){var _=w[p];_.username==l.value&&(v=_)}v||(v=w[0])}else"existingUsername",o("Password not filled. None of the stored logins match the username already present.")}else if(1==c.length)v=c[0];else{var w;v=(w=l?c.filter(function(e){return e.username}):c.filter(function(e){return!e.username}))[0]}var b=!1;if(v&&n&&!g){if(l){var y=l.disabled||l.readOnly,F=v.username!=l.value,L=i&&F&&l.value.toLowerCase()==v.username.toLowerCase();y||L||!F||(l.value=v.username,u(l,"keydown",40),u(l,"keyup",40))}f.value!=v.password&&(f.value=v.password,u(f,"keydown",40),u(f,"keyup",40)),b=!0}else v&&!n?("noAutofillForms",o("autofillForms=false but form can be filled; notified observers")):v&&g&&("autocompleteOff",o("autocomplete=off but form can be filled; notified observers"));return[b,s]}},t={_getPasswordOrigin:function(e,n){return e},_getActionOrigin:function(e){var n=e.action;return""==n&&(n=e.baseURI),this._getPasswordOrigin(n,!0)}},i=document.body;new MutationObserver(function(e){for(var n=0;n<e.length;++n)a(e[n].addedNodes)}).observe(i,{attributes:!1,childList:!0,characterData:!1,subtree:!0}),window.addEventListener("load",function(e){for(var n=0;n<document.forms.length;n++)l(document.forms[n])}),window.addEventListener("submit",function(e){try{n._onFormSubmit(e.target)}catch(e){o(e)}}),Object.defineProperty(window.__firefox__,"logins",{enumerable:!1,configurable:!1,writable:!1,value:Object.freeze(new function(){this.inject=function(e){try{n.receiveMessage(e)}catch(e){}}})})}function o(n){e&&alert(n)}function s(e){n.onUsernameInput(e)}function a(e){for(var n=0;n<e.length;n++){var t=e[n];"FORM"===t.nodeName?l(t):t.hasChildNodes()&&a(t.childNodes)}return!1}function l(e){try{n._asyncFindLogins(e,{}).then(function(e){n.loginsFound(e.form,e.loginsFound)}).then(null,o)}catch(e){o(e)}}function u(e,n,t){var r=document.createEvent("KeyboardEvent");r.initKeyboardEvent(n,!0,!0,window,0,0,0,0,0,t),e.dispatchEvent(r)}}()},function(e,n,t){"use strict";window.__firefox__.includeOnce("PrintHandler")||(window.print=function(){webkit.messageHandlers.printHandler.postMessage({})})}]);
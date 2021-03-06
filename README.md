NimbusFoundry
========

NimbusFoundry is a framework built on top of AngularJS that reduces the work to build an app by prebuilding components such as user login, data storage, and user management. You can build the custom parts of your app by putting them into Angular based plugins.

#### [Getting started with NimbusFoundry](http://nimbusfoundry.com/tutorial.html)
Learn how to get a NimbusFoundry project up and running from cloning our github respository.

#### [NimbusFoundry plugins explained](http://nimbusfoundry.com/tutorial-plugin.html)
Now that you got NimbusFoundry running. Let's learn about how plugins works and more complex features, and write your first plugin!

#### [NimbusFoundry models explained](http://nimbusfoundry.com/modeldoc.html)
Explain how to add/edit/delete/create model instances. Also go into how NimbusFoundry can create forms for model objects automatically.

#### [NimbusFoundry built-in plugins](http://nimbusfoundry.com/plugins.html)
Learn about the built-in plugins on NimbusFoundry.

#### [Our SDK documentation](http://nimbusfoundry.com/classdoc.htm)
All of our classes and methods documented.

# Basic Installation

#### Github fork

You can directly fork this repository as a base project, then you can write your own code under app/

Change the google app id to host this on your own gh-page as a real working app [here](https://github.com/NimbusFoundry/Foundry/blob/gh-pages/app/app.js#L24)

#### Terminal

Or you can use the command-line tool **foundry-cli** to complete this.

 ```
sudo npm install -g foundry-cli
foundry-cli create Name
 ```

#### Change Domain
You can create a **CNAME** file at the root directory, and put your own domain in there like below, then you can access the app using that url.

```
www.example.com
```

# Support

If you have any question about this framework, you can feel free to conatct us directly via admin#nimbusfoundry.com (replace the # with @)

If you want to get the source: look at this [repository](https://github.com/NimbusFoundry/FoundrySource)

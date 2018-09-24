
# The configuration file in detail

In this section, we will go through the `example.test.yml` step by step as I will explain the options available.

The configuration file is split into few sections:

* EasyEngine
* Wordpress Installation
* Workflow
* Plugins
* Themes
* Setup

## Installation
* With **`wplocale`** you can select what language to download and install WordPress. Use language Codes like `en_US` or `en_GB`.
* Add your timezone as string to **`timezone`**. See [List of Supported Timezones](http://php.net/manual/en/timezones.php).
* **`admin`** defines the default admin user. Set your preferred username, password and email.

```yaml
# INSTALLATION
#################################################################

# Easyengine settings
#################################################################

# Easyengine config delete/enable/disable/create
ee_site_config: create

# Easyengine add --wp flag
ee_app_wp: true

# Easyengine change default public directory, default 'htdocs'
ee_app_public: ""


# INSTALLATION
#################################################################

# elementor, cdkrock, bedrock
wpworkflow: ""

# app repo
app_repo: ""

# language/timezone
wplocale: en_US
timezone: "Europe/London"

# admin user settings optional
admin:
  user: ""
  password: ""
  email: ""
  first_name: ""
  last_name: ""
```

## Settings
* In **`wpsettings`** you can define WP-Options like url, title, description, the permalink_structure or edit the default image sizes and more.
* Set **`page_on_front`** to true to set **`frontpage_name`** as default front page.
* If you set **`convert_smilies`** false, smilies wont be converted to image-smilies automatically.

```yaml
# SETTINGS
#################################################################

wpsettings:
  description: Example Description
  permalink_structure: "/%postname%/"
  thumbnail_width: 150
  thumbnail_height: 150
  medium_width: 300
  medium_height: 300
  large_width: 768
  large_height: 768
  blog_public: 0
  # use page as frontpage
  page_on_front: true
  # define frontpage name (requires `page_on_front: true`)
  frontpage_name: Homepage
  # automatic conversion of smilies
  convert_smilies: false
  # Comments and pingback setup
  default_pingback_flag: 0
  default_ping_status: 0
  default_comment_status: 0
  comment_registration: 1
  comment_moderation: 1
  # Time and date format
  date_format: "d/m/Y"
  time_format: "H:i"
  uploads_use_yearmonth_folders: 0
```

## Themes
Now you can install a (starter-) theme if you want. Simply add the name and download-url of the theme. WP Distillery will then download, unzip and install the theme. If you do not leave **`rename`** empty, it will also rename the installed theme folder. By default, WPDistillery/vagrant-easyengine will also delete the delete the default WordPress themes defined at **`remove`**. If you don't want this, just leave it empty: `remove: ""`.

```yaml
# THEMES
#################################################################

# install a custom theme via url, rename it and remove default themes
themes:
  name: WPSeed
  url: "https://github.com/flurinduerst/WPSeed/archive/master.zip"
  rename: ""
  remove:
    - twentyfifteen
    - twentysixteen
    - twentyseventeen
```

## Plugins
You can select what plugins you want WP Distillery to install for you. Split into two sections you can define which plugins to download and install, and which to also activate. By default this section contains a few recommendations.

```yaml
# PLUGINS
#################################################################

# plugins to install & activate
plugins_active:
  - disable-comments
  - duplicate-post
  - enable-media-replace
  - favicon-by-realfavicongenerator
  - regenerate-thumbnails
  - simple-page-ordering
  - user-switching
  - google-sitemap-generator

# plugins to install
plugins_inactive:
  #development
  - custom-post-type-ui
  - search-and-replace
  - capability-manager-enhanced
  #administration
  - adminimize
  - admin-menu-editor
  - admin-menu-reorder
  - wordpress-seo
  #security/backup
  - wp-security-audit-log
  - backwpup
```

If you want to install custom or premium plugins you can simply write down the download-url instead of the name. Make sure to add quotes:

```yaml
plugins_active:
  - "https://example.com/plugins/awesome_plugin.zip&key=31071988"
```

## WPDistillery/vagrant-easyengine Setup
Maybe you don't want to install a theme? Or you prefer keeping the default posts and files it comes with? Within the setup options at the bottom of the file you can tell WPDistillery/vagrant-easyengine which tasks to perform. Simply set those you wan't to skip to `false`.

* **`ee`**: create app and install WordPress core
* **`settings`**: set custom WordPress settings (Note: the value defined **`timezone`** is also considered a setting)
* **`themes`**: install and activate the theme defined above and delete defined default themes
* **`plugins`**: install the plugins listed
* **`cleanup`**: delete WordPress defaults as followed
  * **`comment`**: the default comment
  * **`posts`**: the default post
  * **`files`**: `readme.html`, `license.txt`


```yaml
# WPDISTILLERY SETUP
####################################################################
# if you don't want the setup to run all tasks set them to false

setup:
  ee: true
  settings: true
  theme: true
  plugins: true
  cleanup: true
  # adjust what data you want to be deleted within the cleanup (requires `cleanup: true`)
  comment: true
  posts: true
  files: true
```

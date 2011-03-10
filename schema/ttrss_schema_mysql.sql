SET NAMES utf8;
SET CHARACTER SET utf8;

drop table if exists ttrss_access_keys;
drop table if exists ttrss_user_labels2;
drop table if exists ttrss_labels2;
drop table if exists ttrss_feedbrowser_cache;
drop table if exists ttrss_version;
drop table if exists ttrss_labels;
drop table if exists ttrss_filters;
drop table if exists ttrss_filter_types;
drop table if exists ttrss_filter_actions;
drop table if exists ttrss_user_prefs;
drop table if exists ttrss_prefs;
drop table if exists ttrss_prefs_types;
drop table if exists ttrss_prefs_sections; 
drop table if exists ttrss_tags;
drop table if exists ttrss_enclosures;
drop table if exists ttrss_settings_profiles;
drop table if exists ttrss_entry_comments;
drop table if exists ttrss_user_entries;
drop table if exists ttrss_entries;
drop table if exists ttrss_scheduled_updates;
drop table if exists ttrss_counters_cache;
drop table if exists ttrss_cat_counters_cache;
drop table if exists ttrss_feeds;
drop table if exists ttrss_archived_feeds;
drop table if exists ttrss_feed_categories;
drop table if exists ttrss_users;
drop table if exists ttrss_themes;
drop table if exists ttrss_sessions;

begin;

create table ttrss_themes(id integer not null primary key auto_increment,
	theme_name varchar(200) not null,
	theme_path varchar(200) not null) TYPE=InnoDB DEFAULT CHARSET=UTF8;

insert into ttrss_themes (theme_name, theme_path) values ('Old-skool', 'compat');
insert into ttrss_themes (theme_name, theme_path) values ('Graycube', 'graycube');
insert into ttrss_themes (theme_name, theme_path) values ('Default (Compact)', 'compact');
insert into ttrss_themes (theme_name, theme_path) values ('Three-pane', '3pane');

create table ttrss_users (id integer primary key not null auto_increment,
	login varchar(120) not null unique,
	pwd_hash varchar(250) not null,
	last_login datetime default null,
	access_level integer not null default 0,
	theme_id integer default null,
	email varchar(250) not null default '',
	full_name varchar(250) not null default '',
	email_digest bool not null default false,
	last_digest_sent datetime default null,
	created datetime default null,
	twitter_oauth longtext default null,
	index (theme_id),
	foreign key (theme_id) references ttrss_themes(id)) TYPE=InnoDB DEFAULT CHARSET=UTF8;

insert into ttrss_users (login,pwd_hash,access_level) values ('admin', 
	'SHA1:5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8', 10);

create table ttrss_feed_categories(id integer not null primary key auto_increment,
	owner_uid integer not null,
	title varchar(200) not null,
	collapsed bool not null default false,
	order_id integer not null default 0,
	index(owner_uid),
	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create table ttrss_archived_feeds (id integer not null primary key,
	owner_uid integer not null,
	title varchar(200) not null, 
	feed_url text not null, 
	site_url varchar(250) not null default '',
	index(owner_uid),
	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create table ttrss_counters_cache (
	feed_id integer not null,
	owner_uid integer not null,
	value integer not null default 0,
	updated datetime not null,
	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE
);

create index ttrss_counters_cache_feed_id_idx on ttrss_counters_cache(feed_id);
create index ttrss_counters_cache_owner_uid_idx on ttrss_counters_cache(owner_uid);
create index ttrss_counters_cache_value_idx on ttrss_counters_cache(value);

create table ttrss_cat_counters_cache (
	feed_id integer not null,
	owner_uid integer not null,
	value integer not null default 0,
	updated datetime not null,
	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE
);

create index ttrss_cat_counters_cache_owner_uid_idx on ttrss_cat_counters_cache(owner_uid);

create table ttrss_feeds (id integer not null auto_increment primary key,
	owner_uid integer not null,
	title varchar(200) not null, 
	cat_id integer default null,
	feed_url text not null, 
	icon_url varchar(250) not null default '',
	update_interval integer not null default 0,
	purge_interval integer not null default 0,
	last_updated datetime default 0,
	last_error varchar(250) not null default '',
	site_url varchar(250) not null default '',
	auth_login varchar(250) not null default '',
	auth_pass varchar(250) not null default '',
	parent_feed integer default null,
	private bool not null default false,
	rtl_content bool not null default false,
	hidden bool not null default false,
	include_in_digest boolean not null default true,
	cache_images boolean not null default false,
	auth_pass_encrypted boolean not null default false,
	last_viewed datetime default null,
	last_update_started datetime default null,
	always_display_enclosures boolean not null default false,
	update_method integer not null default 0,
	order_id integer not null default 0,
	index(owner_uid),
	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE,
	index(cat_id),
	foreign key (cat_id) references ttrss_feed_categories(id) ON DELETE SET NULL,
	index(parent_feed),
	foreign key (parent_feed) references ttrss_feeds(id) ON DELETE SET NULL) TYPE=InnoDB DEFAULT CHARSET=UTF8;

insert into ttrss_feeds (owner_uid, title, feed_url) values
	(1, 'Tiny Tiny RSS: New Releases', 'http://tt-rss.org/releases.rss');

insert into ttrss_feeds (owner_uid, title, feed_url) values 
	(1, 'Tiny Tiny RSS: Forum', 'http://tt-rss.org/forum/rss.php');

create table ttrss_entries (id integer not null primary key auto_increment, 
	title text not null, 
	guid varchar(255) not null unique, 
	link text not null, 
	updated datetime not null, 
	content longtext not null,
	content_hash varchar(250) not null,
	no_orig_date bool not null default 0,
	date_entered datetime not null,
	date_updated datetime not null,
	num_comments integer not null default 0,
	comments varchar(250) not null default '',
	author varchar(250) not null default '') TYPE=InnoDB DEFAULT CHARSET=UTF8;

create index ttrss_entries_date_entered_index on ttrss_entries(date_entered);
create index ttrss_entries_guid_index on ttrss_entries(guid);
create index ttrss_entries_updated_idx on ttrss_entries(updated);

create table ttrss_user_entries (
	int_id integer not null primary key auto_increment,
	ref_id integer not null,
	feed_id int, 
	orig_feed_id int, 
	owner_uid integer not null,
	marked bool not null default 0,
	published bool not null default 0,
	tag_cache text not null,
	label_cache text not null,
	last_read datetime,
	score int not null default 0,
	note longtext,
	unread bool not null default 1,
	index (ref_id),
	foreign key (ref_id) references ttrss_entries(id) ON DELETE CASCADE,
	index (feed_id),
	foreign key (feed_id) references ttrss_feeds(id) ON DELETE CASCADE,
	index (orig_feed_id),
	foreign key (orig_feed_id) references ttrss_archived_feeds(id) ON DELETE SET NULL,
	index (owner_uid),
	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create index ttrss_user_entries_unread_idx on ttrss_user_entries(unread);

create table ttrss_entry_comments (id integer not null primary key,
	ref_id integer not null,
	owner_uid integer not null,
	private bool not null default 0,
	date_entered datetime not null,
	index (ref_id),
	foreign key (ref_id) references ttrss_entries(id) ON DELETE CASCADE,
	index (owner_uid),
	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create table ttrss_filter_types (id integer primary key, 
	name varchar(120) unique not null, 
	description varchar(250) not null unique) TYPE=InnoDB DEFAULT CHARSET=UTF8;

insert into ttrss_filter_types (id,name,description) values (1, 'title', 'Title');
insert into ttrss_filter_types (id,name,description) values (2, 'content', 'Content');
insert into ttrss_filter_types (id,name,description) values (3, 'both', 
	'Title or Content');
insert into ttrss_filter_types (id,name,description) values (4, 'link', 
	'Link');
insert into ttrss_filter_types (id,name,description) values (5, 'date', 
	'Article Date');
insert into ttrss_filter_types (id,name,description) values (6, 'author', 'Author');
insert into ttrss_filter_types (id,name,description) values (7, 'tag', 'Article Tags');

create table ttrss_filter_actions (id integer not null primary key, 
	name varchar(120) unique not null, 
	description varchar(250) not null unique) TYPE=InnoDB DEFAULT CHARSET=UTF8;

insert into ttrss_filter_actions (id,name,description) values (1, 'filter', 
	'Delete article');

insert into ttrss_filter_actions (id,name,description) values (2, 'catchup', 
	'Mark as read');

insert into ttrss_filter_actions (id,name,description) values (3, 'mark', 
	'Set starred');

insert into ttrss_filter_actions (id,name,description) values (4, 'tag', 
	'Assign tags');

insert into ttrss_filter_actions (id,name,description) values (5, 'publish', 
	'Publish article');

insert into ttrss_filter_actions (id,name,description) values (6, 'score', 
	'Modify score');

insert into ttrss_filter_actions (id,name,description) values (7, 'label', 
	'Assign label');

create table ttrss_filters (id integer not null primary key auto_increment,
	owner_uid integer not null, 
	feed_id integer default null,
	filter_type integer not null,
	reg_exp varchar(250) not null,
	filter_param varchar(250) not null default '',
	inverse bool not null default false,
	enabled bool not null default true,
	action_id integer not null default 1,
	action_param varchar(250) not null default '',
	index (filter_type),
	foreign key (filter_type) references ttrss_filter_types(id) ON DELETE CASCADE,
	index (owner_uid),
	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE,
	index (feed_id),
	foreign key (feed_id) references ttrss_feeds(id) ON DELETE CASCADE,
	index (action_id),
	foreign key (action_id) references ttrss_filter_actions(id) ON DELETE CASCADE) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create table ttrss_tags (id integer primary key auto_increment, 
	owner_uid integer not null, 
	tag_name varchar(250) not null,
	post_int_id integer not null,
	index (post_int_id),
	foreign key (post_int_id) references ttrss_user_entries(int_id) ON DELETE CASCADE,
	index (owner_uid),
	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create table ttrss_version (schema_version int not null) TYPE=InnoDB DEFAULT CHARSET=UTF8;

insert into ttrss_version values (81);

create table ttrss_enclosures (id integer primary key auto_increment,
	content_url text not null,
	content_type varchar(250) not null,
	post_id integer not null,
	title text not null,
	duration text not null,
	index (post_id),
	foreign key (post_id) references ttrss_entries(id) ON DELETE cascade) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create table ttrss_settings_profiles(id integer primary key auto_increment,
	title varchar(250) not null,
	owner_uid integer not null,
	index (owner_uid),
	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create table ttrss_prefs_types (id integer not null primary key, 
	type_name varchar(100) not null) TYPE=InnoDB DEFAULT CHARSET=UTF8;

insert into ttrss_prefs_types (id, type_name) values (1, 'bool');
insert into ttrss_prefs_types (id, type_name) values (2, 'string');
insert into ttrss_prefs_types (id, type_name) values (3, 'integer');

create table ttrss_prefs_sections (id integer not null primary key, 
	section_name varchar(100) not null) TYPE=InnoDB DEFAULT CHARSET=UTF8;

insert into ttrss_prefs_sections (id, section_name) values (1, 'General');
insert into ttrss_prefs_sections (id, section_name) values (2, 'Interface');
insert into ttrss_prefs_sections (id, section_name) values (3, 'Advanced');

create table ttrss_prefs (pref_name varchar(250) not null primary key,
	type_id integer not null,
	section_id integer not null default 1,
	short_desc text not null,
	help_text varchar(250) not null default '',
	access_level integer not null default 0,
	def_value text not null,
	index(type_id),
	foreign key (type_id) references ttrss_prefs_types(id),
	index(section_id),
	foreign key (section_id) references ttrss_prefs_sections(id)) TYPE=InnoDB DEFAULT CHARSET=UTF8;

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('PURGE_OLD_DAYS', 3, '60', 'Purge old posts after this number of days (0 - disables)',1);
insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('UPDATE_POST_ON_CHECKSUM_CHANGE', 1, 'true', 'Update post on checksum change',1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('DEFAULT_UPDATE_INTERVAL', 3, '30', 'Default interval between feed updates',1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('DEFAULT_ARTICLE_LIMIT', 3, '30', 'Amount of articles to display at once',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('ALLOW_DUPLICATE_POSTS', 1, 'true', 'Allow duplicate posts',1, 'This option is useful when you are reading several planet-type aggregators with partially colliding userbase. When disabled, it forces same posts from different feeds to appear only once.');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('ENABLE_FEED_CATS', 1, 'false', 'Enable feed categories',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('SHOW_CONTENT_PREVIEW', 1, 'true', 'Show content preview in headlines list',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('SHORT_DATE_FORMAT', 2, 'M d, G:i', 'Short date format',3);
insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('LONG_DATE_FORMAT', 2, 'D, M d Y - G:i', 'Long date format',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('HEADLINES_SMART_DATE', 1, 'true', 'Use more accessible date/time format for headlines',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('COMBINED_DISPLAY_MODE', 1, 'false', 'Combined feed display',2, 'Display expanded list of feed articles, instead of separate displays for headlines and article content');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('HIDE_READ_FEEDS', 1, 'false', 'Hide feeds with no unread messages',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('ON_CATCHUP_SHOW_NEXT_FEED', 1, 'false', 'On catchup show next feed',2, 'When "Mark as read" button is clicked in toolbar, automatically open next feed with unread articles.');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('FEEDS_SORT_BY_UNREAD', 1, 'false', 'Sort feeds by unread articles count',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('MARK_UNREAD_ON_UPDATE', 1, 'false', 'Set articles as unread on update',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('REVERSE_HEADLINES', 1, 'false', 'Reverse headline order (oldest first)',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('DIGEST_ENABLE', 1, 'false', 'Enable e-mail digest',1, 'This option enables sending daily digest of new (and unread) headlines on your configured e-mail address');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('CONFIRM_FEED_CATCHUP', 1, 'true', 'Confirm marking feed as read',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('CDM_AUTO_CATCHUP', 1, 'false', 'Automatically mark articles as read',3, 'This option enables marking articles as read automatically while you scroll article list.');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_DEFAULT_VIEW_MODE', 2, 'adaptive', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_DEFAULT_VIEW_LIMIT', 3, '30', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_PREFS_ACTIVE_TAB', 2, '', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('STRIP_UNSAFE_TAGS', 1, 'true', 'Strip unsafe tags from articles', 3, 'Strip all but most common HTML tags when reading articles.');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('BLACKLISTED_TAGS', 2, 'main, generic, misc, uncategorized, blog, blogroll, general, news', 'Blacklisted tags', 3, 'When auto-detecting tags in articles these tags will not be applied (comma-separated list).');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('FRESH_ARTICLE_MAX_AGE', 3, '24', 'Maximum age of fresh articles (in hours)',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('DIGEST_CATCHUP', 1, 'false', 'Mark articles in e-mail digest as read',1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('CDM_EXPANDED', 1, 'true', 'Automatically expand articles in combined mode',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('PURGE_UNREAD_ARTICLES', 1, 'true', 'Purge unread articles',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('HIDE_READ_SHOWS_SPECIAL', 1, 'true', 'Show special feeds when hiding read feeds',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('VFEED_GROUP_BY_FEED', 1, 'false', 'Group headlines in virtual feeds',2, 'When this option is enabled, headlines in Special feeds and Labels are grouped by feeds');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('STRIP_IMAGES', 1, 'false', 'Do not show images in articles', 2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_DEFAULT_VIEW_ORDER_BY', 2, 'default', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('ENABLE_API_ACCESS', 1, 'false', 'Enable external API', 3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_COLLAPSED_SPECIAL', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_COLLAPSED_LABELS', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_COLLAPSED_UNCAT', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_COLLAPSED_FEEDLIST', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_MOBILE_ENABLE_CATS', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_MOBILE_SHOW_IMAGES', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_MOBILE_HIDE_READ', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_MOBILE_SORT_FEEDS_UNREAD', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_THEME_ID', 2, '0', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('USER_TIMEZONE', 2, 'UTC', 'User timezone', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('USER_STYLESHEET', 2, '', 'Customize stylesheet', 2, 'Customize CSS stylesheet to your liking');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('SORT_HEADLINES_BY_FEED_DATE', 1, 'true', 'Sort headlines by feed date',3, 'Use feed-specified date to sort headlines instead of local import date.');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_MOBILE_BROWSE_CATS', 1, 'true', '', 1);

create table ttrss_user_prefs (
   owner_uid integer not null,
   pref_name varchar(250),
   value longtext not null,
	profile integer,
	index (profile),
  	foreign key (profile) references ttrss_settings_profiles(id) ON DELETE CASCADE,
	index (owner_uid),
 	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE,
	index (pref_name),
	foreign key (pref_name) references ttrss_prefs(pref_name) ON DELETE CASCADE) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create table ttrss_scheduled_updates (id integer not null primary key auto_increment,
	owner_uid integer not null,
	feed_id integer default null,
	entered datetime not null,
	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE,
	foreign key (feed_id) references ttrss_feeds(id) ON DELETE CASCADE) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create table ttrss_sessions (id varchar(250) unique not null primary key,
	data text,
	expire integer not null,
	index (id), 
	index (expire)) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create table ttrss_feedbrowser_cache (
	feed_url text not null,
	title text not null,
	subscribers integer not null) DEFAULT CHARSET=UTF8;	

create table ttrss_labels2 (id integer not null primary key auto_increment, 
	owner_uid integer not null,
	caption varchar(250) not null,
	fg_color varchar(15) not null default '',
	bg_color varchar(15) not null default '',
	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE
) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create table ttrss_user_labels2 (label_id integer not null,
	article_id integer not null,
	foreign key (label_id) references ttrss_labels2(id) ON DELETE CASCADE,
	foreign key (article_id) references ttrss_entries(id) ON DELETE CASCADE
) TYPE=InnoDB DEFAULT CHARSET=UTF8;

create table ttrss_access_keys (id serial not null primary key,
	access_key varchar(250) not null,
	feed_id varchar(250) not null,
	is_cat bool not null default false,
	owner_uid integer not null,
  	foreign key (owner_uid) references ttrss_users(id) ON DELETE CASCADE) TYPE=InnoDB DEFAULT CHARSET=UTF8;

commit;

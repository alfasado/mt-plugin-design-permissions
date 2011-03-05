package DesignPermissions::Plugin;

use strict;

sub _pre_run {
    my $app = MT->instance;
    no warnings 'redefine';
    *StyleCatcher::CMS::js = \&_js;
    my $core = MT->component( 'core' );
    if ( my $stylecatcher = MT->component( 'StyleCatcher' ) ) {
        my $r = $stylecatcher->registry( 'applications', 'cms', 'menus' );
        $r->{ 'design:theme' } = { label      => MT->translate( 'Styles' ),
                                   order      => 300,
                                   mode       => 'stylecatcher_theme',
                                   view       => [ 'blog', 'website' ],
                                   permission => 'edit_style', };
    }
    my $cr = $core->registry( 'applications', 'cms', 'menus' );
    $cr->{ 'design:widgets' } = { label             => MT->translate( 'Widgets' ),
                                  order             => 200,
                                  mode              => 'list_widget',
                                  permission        => 'edit_widgets',
                                  system_permission => 'edit_templates',
                                  view              => [ "blog", 'website', 'system' ] };
    if ( my $blog = $app->blog ) {
        if (! is_user_can( $blog, $app->user, 'edit_templates' ) ) {
            $cr->{ 'design:template' } = { label             => "Templates",
                                           order             => 100,
                                           mode              => 'list_template',
                                           permission        => 'administer_blog',
                                           system_permission => 'edit_templates',
                                           view              => [ "blog", 'website', 'system' ], };
        }
        if ( ( $app->mode eq 'list_widget' ) || ( $app->mode eq 'edit_widget' ) || ( $app->mode eq 'save_widget' ) ) {
            if (! is_user_can( $blog, $app->user, 'edit_widgets' ) ) {
                $app->return_to_dashboard( permission => 1 );
            } else {
                my $perms = $app->permissions->{ column_values }->{ permissions };
                $app->permissions->{ column_values }->{ permissions } = "$perms,'edit_templates'";
            }
        }
        if ( ( $app->mode eq 'stylecatcher_theme' ) || ( $app->mode eq 'stylecatcher_apply' ) ) {
            if (! is_user_can( $blog, $app->user, 'edit_style' ) ) {
                $app->return_to_dashboard( permission => 1 );
            } else {
                my $perms = $app->permissions->{ column_values }->{ permissions };
                $app->permissions->{ column_values }->{ permissions } = "$perms,'edit_templates'";
            }
        }
    }
}

sub _js {
    my $app = shift;
    return $app->json_error( $app->errstr ) unless $app->validate_magic;
    require StyleCatcher::CMS;
    my $data = StyleCatcher::CMS::fetch_themes( $app->param( 'url' ) ) or return $app->json_error( $app->errstr );
    return $app->json_result( $data );
}

sub is_user_can {
    my ( $blog, $user, $permission ) = @_;
    $permission = 'can_' . $permission;
    my $perm = $user->is_superuser;
    unless ( $perm ) {
        if ( $blog ) {
            my $admin = 'can_administer_blog';
            $perm = $user->permissions( $blog->id )->$admin;
            $perm = $user->permissions( $blog->id )->$permission unless $perm;
        } else {
            $perm = $user->permissions()->$permission;
        }
    }
    return $perm;
}

1;
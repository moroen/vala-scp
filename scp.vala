public class scp : Object {
    private string keyfile1;
    private string keyfile2;

    private string hostaddress;
    private string username;
    private string password;

    private string remote_path;
    private string local_path;

    public scp(string host, string username, string password, string local_path, string remote_path) {
            this.hostaddress = host;
            this.username = username;
            this.password = password;
            this.local_path = local_path;
            this.remote_path = remote_path;
    }

    public virtual void show_progress(ssize_t current, ssize_t total) {}
    
    private bool connect_session (out SSH2.Session session, out int sock) {

        // Initalize out variables, they will be assigned later
        sock = 0;
        session = null;

        string home=GLib.Environment.get_home_dir();
        keyfile1=home+"/.ssh/id_rsa.pub";
        keyfile2=home+"/.ssh/id_rsa";
        // username=host_info.username;
        // password=host_info.password;
        uint32 hostaddr = Posix.inet_addr(hostaddress);

        /*
        uint32 hostaddr;
        if (args.length > 1) {
            hostaddr = Posix.inet_addr(args[1]);
        } else {
            hostaddr = Posix.htonl(0x7F000001);
        }
        */


        var rc = SSH2.init (0);
        if (rc != SSH2.Error.NONE) {
            stdout.printf ("libssh2 initialization failed (%d)\n", rc);
            return false;
        }

        /* Ultra basic "connect to port 22 on hostaddr".  Your code is
        * responsible for creating the socket establishing the connection
        */
        sock = Posix.socket(Posix.AF_INET, Posix.SOCK_STREAM, 0);

        Posix.SockAddrIn sin = Posix.SockAddrIn();
        sin.sin_family = Posix.AF_INET;
        sin.sin_port = Posix.htons(22);
        sin.sin_addr.s_addr = hostaddr;
        if (Posix.connect(sock, &sin,
                    sizeof(Posix.SockAddrIn)) != 0) {
            stderr.printf("failed to connect!\n");
            return false;
        }

        /* Create a session instance and start it up. This will trade welcome
        * banners, exchange keys, and setup crypto, compression, and MAC layers
        */
        session = SSH2.Session.create<bool>();
        if (session.handshake(sock) != SSH2.Error.NONE) {
            stderr.printf("Failure establishing SSH session\n");
            return false;
        }

        /* At this point we havn't authenticated. The first thing to do is check
        * the hostkey's fingerprint against our known hosts Your app may have it
        * hard coded, may go to a file, may present it to the user, that's your
        * call
        */
        var fingerprint = session.get_host_key_hash(SSH2.HashType.SHA1);
        stdout.printf("Fingerprint: ");
        for(var i = 0; i < 20; i++) {
            stdout.printf("%02X ", fingerprint[i]);
        }
        stdout.printf("\n");

        /* check what authentication methods are available */
        int auth_pw = 0;
        var userauthlist = session.list_authentication(username.data);
        stdout.printf("Authentication methods: %s\n", userauthlist);
        if ( "password" in userauthlist) {
            auth_pw |= 1;
        }
        if ( "keyboard-interasend();ctive" in userauthlist) {
            auth_pw |= 2;
        }
        if ( "publickey" in userauthlist) {
            auth_pw |= 4;
        }

    

        if ((auth_pw & 1)!=0) {
            /* We could authenticate via password */
            if (session.auth_password(username, password) != SSH2.Error.NONE) {
                stdout.printf("\tAuthentication by password failed!\n");
                session.disconnect( "Normal Shutdown, Thank you for playing");
                session = null;
                Posix.close(sock);
                return false;
            } else {
                stdout.printf("\tAuthentication by password succeeded.\n");
            }
        } else if ((auth_pw & 4)!=0) {
            /* Or by public key */
            if (session.auth_publickey_from_file(username, keyfile1, keyfile2, password) != SSH2.Error.NONE) {
                stdout.printf("\tAuthentication by public key failed!\n");
                session.disconnect( "Normal Shutdown, Thank you for playing");
                session = null;
                Posix.close(sock);
                return false;
            } else {
                stdout.printf("\tAuthentication by public key succeeded.\n");
            }
        } else {
            stdout.printf("No supported authentication methods found!\n");
            session.disconnect( "Normal Shutdown, Thank you for playing");
            session = null;
            Posix.close(sock); 
            return false;
        }
        return true;
    }

    public ssize_t send() 
    {

        SSH2.Session session;
        int sock;

        Posix.Stat info;
        SSH2.Channel? channel = null;

        Posix.lstat(this.local_path, out info);
        stdout.printf("Local Size: %s\n", info.st_size.to_string());

        this.connect_session(out session, out sock);

        if (session.authenticated && (channel = session.scp_send(this.remote_path, info.st_mode & 0777, info.st_size, info.st_mtime, info.st_atime)) == null) {
            stderr.printf("Unable to open a session\n");
        } else {
            
            try {
                File file = File.new_for_path(this.local_path);
                int buffer_size = 128;
                var buffer = new uint8[buffer_size];

                ssize_t written = 0;
                ssize_t read =0;

                var dis = new DataInputStream(file.read ());

                while (written < info.st_size-buffer_size) {
                    read = dis.read(buffer);
                    written += channel.write(buffer);
                    this.show_progress(written, (ssize_t)info.st_size);
                }
                var rest_buffer = new uint8[info.st_size - written];
                read = dis.read(rest_buffer);
                written += channel.write(rest_buffer);
                this.show_progress(written, (ssize_t)info.st_size);

                channel.send_eof();
                channel.wait_eof();
                channel.wait_closed();
                session.disconnect("Done!");

            } catch (Error e) {
                session.disconnect("Unable to open");
                error ("%s", e.message);
            }
                
           
        }

        return 0;
    }

    public ssize_t receive()
    {

        SSH2.Session session;
        int sock;

        if (!this.connect_session(out session, out sock)) {
            return 0;
        }
        

        /*
        /* Request a shell */
        SSH2.Channel? channel = null;

        Posix.Stat info = Posix.Stat();

        if (session.authenticated && (channel = session.scp_recv2(remote_path, out info)) == null) {
            stderr.printf("Unable to open a session\n");
        } else {

            try {
                stdout.printf("Size: %s\n", info.st_size.to_string());
            
                int buffer_size = 256;
                
                ssize_t read = 0;
                ssize_t written = 0;

                var file = File.new_for_path(local_path);

                // delete if file already exists
                if (file.query_exists ()) {
                    file.delete ();
                }

                var dos = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));
                var buffer = new uint8[buffer_size];

                while (written < info.st_size-buffer_size) {
                    read = channel.read(buffer);
                    written += dos.write(buffer);
                    this.show_progress(written, (ssize_t)info.st_size);
                }
                var rest_buffer = new uint8[info.st_size - written];
                read = channel.read(rest_buffer);
                written += dos.write(rest_buffer);
                this.show_progress(written, (ssize_t)info.st_size);

            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
                return 1;
            } finally {
                channel = null;
            }
        }

        session.disconnect( "Normal Shutdown, Thank you for playing");
        session = null;
        Posix.close(sock);
        stdout.printf("all done!\n");

        SSH2.exit();

        return 0;
    }
}
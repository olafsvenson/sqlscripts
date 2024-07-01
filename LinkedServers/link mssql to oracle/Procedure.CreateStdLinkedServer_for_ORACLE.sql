/*requires Schema.Administration.sql*/

PRINT '--------------------------------------------------------------------------------------------------------------'
PRINT 'PROCEDURE [CreateStdLinkedServer]'
GO 

IF  NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[CreateStdLinkedServer]') AND type in (N'P'))
BEGIN
    EXECUTE ('CREATE Procedure [CreateStdLinkedServer] ( ' +
            ' @ServerName    varchar(512), ' +
            ' @DbName    varchar(50) ' +
            ') ' +
            'AS ' +
            'BEGIN ' +
            '   SELECT ''Not implemented'' ' +
            'END')

    IF @@ERROR = 0
        PRINT '   PROCEDURE created.'
    ELSE
    BEGIN
        PRINT '   Error while trying to create procedure'
        RETURN
    END
END
GO


ALTER PROCEDURE [CreateStdLinkedServer] (
    @LinkedServerName   SYSNAME,
    @ServerProduct      nvarchar(128),
    @DataSource         nvarchar(4000),
    @IdentityForwarding varchar(8) = 'true',
    @Username           SYSNAME,
    @Password           SYSNAME,
    --@LocalUser          SYSNAME,
    @debug              TINYINT = 0
)
AS
/*
 ===================================================================================
  DESCRIPTION:
    This procedure creates a linked server according to the given parameters.
    !! Note : it has only been tested on linked server with Oracle Database 11.1.0.7
    with Oracle Client 11.2 !!


  ARGUMENTS :
    @LinkedServerName       Logical name for the linked server

    @ServerProduct          The product name of the OLE DB data source to add as a
                            linked server.
                            Default value : null
                            Possible values :   "SQL Server" - "Oracle"


    @debug          if set to 1, this enables the debug mode

  REQUIREMENTS:
    Installation at least of a Oracle Database Instant Client at least. Running or execution preferred
        You can go in custom installation so that you add ODBC and OleDB sources

    Environment variable set : (Example !!)
        %ORACLE_BASE%=C:\app\oracle
        %ORACLE_HOME%=C:\app\oracle\product\11.2.0\client_1



  EXAMPLE USAGE :

 = Command
USE [DBA]
EXEC [dbo].[CreateStdLinkedServer]
    @LinkedServerName   = 'DOSMED.ST.CHULG',
    @ServerProduct      = 'Oracle',
    @DataSource         = 'DOSMED.ST.CHULG',
    @IdentityForwarding = 'FALSE',
    @Username           = 'sdsq',
    @Password           = 'sdqsqs',
    --@LocalUser          = NULL,
    @debug              = 1


= test connection :

select 1 a from [DOSMED.ST.CHULG]..sys.dual
SELECT * FROM OPENQUERY([DOSMED.ST.CHULG] , 'select sysdate from dual')
-- if rpc activated :
exec ('select sysdate from SYS.DUAL') AT [DOSMED.ST.CHULG]

SELECT * FROM OPENQUERY([DOSMED.ST.CHULG] , 'select * from PM_PHARMA_ROBOT')

-- if rpc activated  :
exec ('select * from PM_PHARMA_ROBOT') AT [DOSMED.ST.CHULG]

= Remove linked server :
USE [master]
EXEC master.dbo.sp_dropserver @server=N'DOSMED.ST.CHULG', @droplogins='droplogins'
GO



  ==================================================================================
  BUGS:

    BUGID       Fixed   Description
    ==========  =====   ==========================================================
    ----------------------------------------------------------------------------------
  ==================================================================================
  NOTES:
  AUTHORS:
       .   VBO     Vincent Bouquette   (vincent.bouquette@chu.ulg.ac.be)
       .   BBO     Bernard Bozert      (bernard.bozet@chu.ulg.ac.be)
       .   JEL     Jefferson Elias     (jelias@chu.ulg.ac.be)

  COMPANY: CHU Liege
  ==================================================================================
  Revision History

    Date        Nom         Description
    ==========  =====       ==========================================================
    19/11/2014  JEL         Version 0.1.0
    ----------------------------------------------------------------------------------
    01/12/2014  JEL         Added some options for OracleOleDB Provider
    ----------------------------------------------------------------------------------
    12/08/2015  JEL         Commented action about index as access pass Oracle OLEDB
                            provider settings.
                            It can lead to unexpected errors and therefore is not
                            suitable for production environment.
    ----------------------------------------------------------------------------------
 ===================================================================================
*/

BEGIN

    --SET NOCOUNT ON;

    DECLARE @versionNb        varchar(16) = '0.1.1';
    DECLARE @tsql             nvarchar(max);            -- text to execute via dynamic SQL

    --
    -- check parameters
    -- Existing linked server ?
    --
    if EXISTS (SELECT 1 FROM sys.sysservers where srvname = @LinkedServerName )
    BEGIN
        RAISERROR('A linked server with this name already exists !', 10,1,@LinkedServerName )
    END

    -- Allowed Server Product
    --
    if @ServerProduct not in ('SQL Server','Oracle')
    BEGIN
        RAISERROR('Wrong parameter ServerProduct', 10,1,@ServerProduct )
    END

    --
    -- Deduct variable values from input params.
    -- (some additional check can be done)
    -- provider name
    --

    DECLARE @ProviderName  nvarchar(4000) = NULL

    if @ServerProduct = 'Oracle'
    BEGIN
        SET @ProviderName = 'OraOLEDB.Oracle'

        if @debug = 1
        BEGIN
            PRINT 'Provider set to ' + @ProviderName
        END

        SET @IdentityForwarding = 'FALSE'
        if @debug = '0'
        BEGIN
            PRINT '@IdentityForwarding set to FALSE'
        END

        -- TODO : get to know how to check these properties

        if @debug = 1
        BEGIN
            PRINT 'Configuring SQL Server to be able to connect to an Oracle Database'
        END

        EXEC master.dbo.sp_MSset_oledb_prop 'ORAOLEDB.Oracle', N'AllowInProcess', 1

        if @debug = 1
        BEGIN
            PRINT 'Configure it to accept dynamic parameters.'
        END

        EXEC master.dbo.sp_MSset_oledb_prop 'ORAOLEDB.Oracle', N'DynamicParameters', 1

        if @debug = 1
        BEGIN
            --PRINT 'Configure it to take Indexes when it''s possible.'
            PRINT 'Ensure it does NOT take Indexes when it''s possible. (Can lead to Msg 7319 Level 16 if the option is enabled)'
        END

        --EXEC master.dbo.sp_MSset_oledb_prop N'OraOLEDB.Oracle', N'IndexAsAccessPath', 1
        EXEC master.dbo.sp_MSset_oledb_prop N'OraOLEDB.Oracle', N'IndexAsAccessPath', 0

        if @debug = 1
        BEGIN
            PRINT 'Configure it to allow nested queries.'
        END

        EXEC master.dbo.sp_MSset_oledb_prop N'OraOLEDB.Oracle', N'NestedQueries', 1

        if @debug = 1
        BEGIN
            PRINT 'Configure it to allow LIKE operator in queries.'
        END

        EXEC master.dbo.sp_MSset_oledb_prop N'OraOLEDB.Oracle', N'SqlServerLIKE', 1


        if @Username is null
        BEGIN
            RAISERROR('No username provided although an heterogenous connection asked', 10,1,@Username )
        END

        if @Password is null
        BEGIN
            RAISERROR('No password provided', 10,1,@Password)
        END

    END


    if @debug = 1
    BEGIN
            PRINT '----------------------------------------------------'
            PRINT OBJECT_NAME(@@PROCID)
            PRINT '===================================================='
            PRINT 'LinkedServerName   = ' + @LinkedServerName
            PRINT 'ServerProduct      = ' + @ServerProduct
            PRINT 'DataSource         = ' + @DataSource
            PRINT 'IdentityForwarding = ' + convert(varchar,@IdentityForwarding )
            PRINT 'Username           = ' + @Username
            PRINT 'Password           = ' + @Password;
            --PRINT 'LocalUser          = ' + isnull(@LocalUser,'#N/A');
            PRINT 'ProviderName       = ' + @ProviderName
            PRINT '----------------------------------------------------'
            PRINT CHAR(10)
    END


    BEGIN TRY
        DECLARE @valback INT
        EXEC @valback = sp_addlinkedserver
                @server     = @LinkedServerName,
                @srvProduct = @ServerProduct,
                @provider   = @ProviderName,
                @datasrc    = @DataSource,
                @location   = NULL,
                @provstr    = NULL, -- custom parameters for provider
                @catalog    = NULL

        if(@valback = 1)
        BEGIN
            RAISERROR('Unable to add linked server', 10,1,@LinkedServerName)
        END

        exec @valback =  sp_addlinkedsrvlogin
                @rmtsrvname  = @LinkedServerName,
                @useself     = @IdentityForwarding,
                @rmtuser     = @Username,
                @rmtpassword = @Password

        if(@valback = 1)
        BEGIN
            RAISERROR('Unable to add login for linked linked server', 10,1,@LinkedServerName,@Username)
        END

        PRINT 'Linked server ' + @LinkedServerName + ' created successfully'

        if @debug = 1
        BEGIN
            PRINT 'Now configuring this linked server'
        END
        EXEC master.dbo.sp_MSset_oledb_prop N'MSDASQL', N'LevelZeroOnly', 1
        EXEC master.dbo.sp_MSset_oledb_prop N'MSDASQL', N'NestedQueries', 1
        EXEC master.dbo.sp_MSset_oledb_prop N'MSDASQL', N'SqlServerLIKE', 1

        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'collation compatible', @optvalue=N'false'
        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'data access', @optvalue=N'true'
        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'dist', @optvalue=N'false'
        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'pub', @optvalue=N'false'
        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'rpc', @optvalue=N'true' -- allow remote server to call a stored procedure on local server
        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'rpc out', @optvalue=N'true' -- "rpc out" definitely must be enabled to call a stored procedure on the remote server.
        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'sub', @optvalue=N'false'
        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'connect timeout', @optvalue=N'0'
        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'collation name', @optvalue=null
        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'lazy schema validation', @optvalue=N'false'
        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'query timeout', @optvalue=N'0'
        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'use remote collation', @optvalue=N'true'
        EXEC master.dbo.sp_serveroption @server=@LinkedServerName, @optname=N'remote proc transaction promotion', @optvalue=N'true'


    END TRY

    BEGIN CATCH

        PRINT 'ErrorNumber    : ' + CONVERT (VARCHAR , ERROR_NUMBER())
        PRINT 'ErrorSeverity  : ' + CONVERT (VARCHAR , ERROR_SEVERITY())
        PRINT 'ErrorState     : ' + CONVERT (VARCHAR , ERROR_STATE())
        PRINT 'ErrorProcedure : ' + CONVERT (VARCHAR , ERROR_PROCEDURE())
        PRINT 'ErrorLine      : ' + CONVERT (VARCHAR , ERROR_LINE())
        PRINT 'ErrorMessage   : ' + CONVERT (VARCHAR , ERROR_MESSAGE())
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN --RollBack in case of Error

    END CATCH

END
GO

IF @@ERROR = 0
    PRINT '   PROCEDURE altered.'
ELSE
BEGIN
    PRINT '   Error while trying to alter procedure'
    RETURN
END
GO 

PRINT '--------------------------------------------------------------------------------------------------------------'
PRINT ''
GO


/**

MSDN Doc :
==============================

Arguments
*********

sp_addlinkedserver [ @server= ] 'server' [ , [ @srvproduct= ] 'product_name' ]
     [ , [ @provider= ] 'provider_name' ]
     [ , [ @datasrc= ] 'data_source' ]
     [ , [ @location= ] 'location' ]
     [ , [ @provstr= ] 'provider_string' ]
     [ , [ @catalog= ] 'catalog' ]

Arguments
*********

    [ @server= ] 'server'

        Nom du serveur li� � cr�er. server est de type sysname et n'a pas de valeur par d�faut.
    [ @srvproduct= ] 'product_name'

        Nom de produit de la source de donn�es OLE DB � ajouter comme serveur li�. product_name est de type nvarchar(128), avec NULL comme valeur par d�faut. Si le nom du produit est SQL Server, il n'est pas n�cessaire de sp�cifier provider_name, data_source, location, provider_string et catalog.
    [ @provider= ] 'provider_name'

        ID de programme unique (PROGID) du fournisseur OLE DB correspondant � la source de donn�es. provider_name doit �tre unique pour le fournisseur OLE DB sp�cifi� install� sur l'ordinateur actuel. provider_name est de type nvarchar( 128 ). Sa valeur par d�faut est NULL ; cependant, si provider_name est omis, SQLNCLI est utilis�. (L'utilisation de SQLNCLI et SQL Server redirigeront vers la version la plus r�cente du fournisseur SQL Server Native Client OLE DB). Le fournisseur OLE DB est cens� �tre enregistr� avec le PROGID sp�cifi� dans le Registre.
    [ @datasrc= ] 'data_source'

        Nom de la source de donn�es, tel qu'il est interpr�t� par le fournisseur OLE DB. data_source est de type nvarchar(4000). data_source est transmis comme propri�t� DBPROP_INIT_DATASOURCE pour initialiser le fournisseur OLE DB.
    [ @location= ] 'location'

        Emplacement de la base de donn�es, tel qu'il est interpr�t� par le fournisseur OLE DB. location est de type nvarchar(4000), avec NULL comme valeur par d�faut. location est transmis comme propri�t� DBPROP_INIT_LOCATION pour initialiser le fournisseur OLE DB.
    [ @provstr= ] 'provider_string'

        Cha�ne de connexion sp�cifique au fournisseur OLE DB identifiant une source de donn�es unique. provider_string est de type nvarchar(4000), avec NULL comme valeur par d�faut. provstr est transmis � IDataInitialize ou d�fini comme propri�t� DBPROP_INIT_PROVIDERSTRING pour initialiser le fournisseur OLE DB.

        Lorsque le serveur li� est cr�� sur le fournisseur SQL Server Native Client OLE DB, l'instance peut �tre sp�cifi�e � l'aide du mot cl� SERVER sous la forme SERVER=servername\instancename, afin de sp�cifier une instance de SQL Server. servername repr�sente le nom de l'ordinateur sur lequel s'ex�cute SQL Server, tandis que instancename repr�sente le nom de l'instance SQL Server sp�cifique � laquelle l'utilisateur doit �tre connect�.

      [ @catalog= ] 'catalog'

        Catalogue � utiliser lors de l'�tablissement d'une connexion au fournisseur OLE DB. catalog est de type sysname, avec NULL comme valeur par d�faut. catalog est transmis comme propri�t� DBPROP_INIT_CATALOG pour initialiser le fournisseur OLE DB. Lorsque le serveur li� est d�fini sur une instance de SQL Server, le catalogue fait r�f�rence � la base de donn�es par d�faut sur laquelle le serveur li� est mapp�.


Valeurs des codes de retour
***************************

    0 (r�ussite) ou 1 (�chec)

*/
/**

sp_addlinkedsrvlogin [ @rmtsrvname = ] 'rmtsrvname'
     [ , [ @useself = ] 'TRUE' | 'FALSE' | NULL ]
     [ , [ @locallogin = ] 'locallogin' ]
     [ , [ @rmtuser = ] 'rmtuser' ]
     [ , [ @rmtpassword = ] 'rmtpassword' ]

Arguments
*********

    [ @rmtsrvname = ] 'rmtsrvname'

        Nom d'un serveur li� auquel s'applique le mappage de la connexion. rmtsrvname est de type sysname et n'a pas de valeur par d�faut.
    [ @useself = ] 'TRUE' | 'FALSE' | 'NULL'

        D�termine si la connexion � rmtsrvname doit �tre r�alis�e en empruntant l'identit� des connexions locales ou en envoyant explicitement un nom d'acc�s et un mot de passe. Le type de donn�es est varchar(8), avec TRUE comme valeur par d�faut.

        La valeur TRUE sp�cifie que les connexions utilisent leurs propres informations d'identification pour se connecter � rmtsrvname. Les arguments rmtuser et rmtpassword sont ignor�s. La valeur FALSE sp�cifie que les arguments rmtuser et rmtpassword sont utilis�s pour la connexion � rmtsrvname pour l'argument locallogin sp�cifi�. Si rmtuser et rmtpassword sont �galement d�finis avec une valeur NULL, aucune connexion et aucun mot de passe n'est utilis� pour la connexion au serveur li�.
    [ @locallogin = ] 'locallogin'

        Connexion sur le serveur local. locallogin est de type sysname, avec NULL comme valeur par d�faut. La valeur NULL sp�cifie que cette entr�e s'applique � l'ensemble des connexions locales �tablies avec l'argument rmtsrvname. Si sa valeur par d�faut n'est pas NULL, locallogin peut �tre une connexion SQL Server ou une connexion Windows. La connexion Windows doit �tre autoris�e � acc�der � SQL Server directement ou par l'interm�diaire de son appartenance � un groupe Windows qui a une autorisation d'acc�s.
    [ @rmtuser = ] 'rmtuser'

        Connexion distante utilis�e pour se connecter � rmtsrvname lorsque la valeur FALSE est attribu�e � @useself. Lorsque le serveur distant est une instance de SQL Server qui n'utilise pas l'authentification Windows, l'argument rmtuser est un compte de connexion SQL Server. rmtuser est de type sysname, avec NULL comme valeur par d�faut.
    [ @rmtpassword = ] 'rmtpassword'

        Mot de passe associ� � rmtuser. rmtpassword est de type sysname, avec NULL comme valeur par d�faut.

Valeurs des codes de retour
***************************

    0 (r�ussite) ou 1 (�chec)


*/


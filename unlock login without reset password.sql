
Use Master
Go
if((select loginproperty('dpa','Islocked'))=1)
begin
	ALTER LOGIN [dpa] WITH  CHECK_POLICY=OFF;

	ALTER LOGIN [dpa] WITH  CHECK_POLICY=ON;
	print 'Login unlocked successfully...'
end

GO
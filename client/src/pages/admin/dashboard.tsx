import { useWorkLogs, useCreateWorkLog } from "@/hooks/use-work-logs";
import { useUsers } from "@/hooks/use-users";
import Layout from "@/components/layout";
import { StatsCard } from "@/components/stats-card";
import { Users, Briefcase, Clock, TrendingUp, Plus, Calendar as CalendarIcon } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import { format, startOfMonth, endOfMonth, eachDayOfInterval, isSameDay } from "date-fns";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogDescription,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";

export default function AdminDashboard() {
  const { data: logs } = useWorkLogs();
  const { data: users } = useUsers();
  const createLog = useCreateWorkLog();
  
  const [selectedEmployee, setSelectedEmployee] = useState<number | undefined>(undefined);
  const [startDate, setStartDate] = useState(format(startOfMonth(new Date()), 'yyyy-MM-dd'));
  const [endDate, setEndDate] = useState(format(endOfMonth(new Date()), 'yyyy-MM-dd'));
  const [open, setOpen] = useState(false);

  // Form State for manual registration
  const [regUserId, setRegUserId] = useState("");
  const [regDate, setRegDate] = useState(format(new Date(), 'yyyy-MM-dd'));
  const [regStartTime, setRegStartTime] = useState("09:00");
  const [regEndTime, setRegEndTime] = useState("18:00");
  const [regType, setRegType] = useState("work");

  const totalEmployees = users?.filter(u => u.role === 'employee').length || 0;
  const filteredLogs = logs?.filter(log => {
    if (selectedEmployee && log.userId !== selectedEmployee) return false;
    if (startDate && log.date < startDate) return false;
    if (endDate && log.date > endDate) return false;
    return true;
  }) || [];

  const totalHours = filteredLogs.reduce((acc, log) => acc + log.totalHours, 0);
  const employees = users?.filter(u => u.role === 'employee') || [];

  const handleManualSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!regUserId) return;
    
    // Simple duration calc for demo (HH:mm)
    const [sH, sM] = regStartTime.split(':').map(Number);
    const [eH, eM] = regEndTime.split(':').map(Number);
    const diff = (eH * 60 + eM) - (sH * 60 + sM);

    await createLog.mutateAsync({
      userId: Number(regUserId),
      date: regDate,
      startTime: regStartTime,
      endTime: regEndTime,
      totalHours: diff > 0 ? diff : 480,
      type: regType as any
    });
    setOpen(false);
  };

  return (
    <Layout>
      <div className="space-y-8">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Panel de Administración</h1>
            <p className="text-muted-foreground mt-1">Gestión de registros y visualización</p>
          </div>
          
          <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
              <Button>
                <Plus className="mr-2 h-4 w-4" /> Registro Manual
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Registrar Jornada / Ausencia</DialogTitle>
                <DialogDescription>Añade un registro histórico para un empleado.</DialogDescription>
              </DialogHeader>
              <form onSubmit={handleManualSubmit} className="space-y-4 pt-4">
                <div className="space-y-2">
                  <Label>Empleado</Label>
                  <Select value={regUserId} onValueChange={setRegUserId}>
                    <SelectTrigger><SelectValue placeholder="Seleccionar" /></SelectTrigger>
                    <SelectContent>
                      {employees.map(e => <SelectItem key={e.id} value={e.id.toString()}>{e.fullName}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Tipo de Registro</Label>
                  <RadioGroup value={regType} onValueChange={setRegType} className="flex gap-4">
                    <div className="flex items-center space-x-2">
                      <RadioGroupItem value="work" id="r1" />
                      <Label htmlFor="r1">Horas Trabajadas</Label>
                    </div>
                    <div className="flex items-center space-x-2">
                      <RadioGroupItem value="absence" id="r2" />
                      <Label htmlFor="r2">Horas Ausencia</Label>
                    </div>
                  </RadioGroup>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Fecha</Label>
                    <Input type="date" value={regDate} onChange={e => setRegDate(e.target.value)} required />
                  </div>
                  <div className="space-y-2">
                    <Label>Duración (Ej: 09:00 - 18:00)</Label>
                    <div className="flex gap-2">
                      <Input type="time" value={regStartTime} onChange={e => setRegStartTime(e.target.value)} />
                      <Input type="time" value={regEndTime} onChange={e => setRegEndTime(e.target.value)} />
                    </div>
                  </div>
                </div>
                <Button type="submit" className="w-full">Guardar Registro</Button>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <Tabs defaultValue="calendar">
          <TabsList>
            <TabsTrigger value="calendar">Vista Calendario</TabsTrigger>
            <TabsTrigger value="table">Vista Tabla</TabsTrigger>
          </TabsList>

          <TabsContent value="calendar" className="mt-4">
            <Card>
              <CardContent className="p-6">
                 <div className="grid grid-cols-7 gap-px bg-muted rounded-lg overflow-hidden border">
                    {['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'].map(d => (
                      <div key={d} className="bg-background p-2 text-center text-xs font-medium text-muted-foreground">{d}</div>
                    ))}
                    {eachDayOfInterval({ start: startOfMonth(new Date()), end: endOfMonth(new Date()) }).map(day => {
                      const dayLogs = filteredLogs.filter(l => isSameDay(new Date(l.date), day));
                      const isFichado = dayLogs.some(l => l.type === 'work');
                      const isAusencia = dayLogs.some(l => l.type === 'absence');
                      
                      return (
                        <div key={day.toString()} className="bg-background min-h-[80px] p-2 border-t">
                          <span className="text-xs text-muted-foreground">{format(day, 'd')}</span>
                          <div className="mt-1 space-y-1">
                            {isFichado && <div className="h-1.5 w-full bg-emerald-500 rounded-full" title="Trabajado" />}
                            {isAusencia && <div className="h-1.5 w-full bg-blue-500 rounded-full" title="Ausencia" />}
                          </div>
                        </div>
                      );
                    })}
                 </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="table" className="mt-4">
             <Card>
                <CardHeader className="flex flex-row items-center justify-between">
                  <CardTitle>Histórico de Registros</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid gap-4 md:grid-cols-4">
                    <Select value={selectedEmployee?.toString() || "0"} onValueChange={(v) => setSelectedEmployee(v === "0" ? undefined : Number(v))}>
                      <SelectTrigger><SelectValue placeholder="Empleado" /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="0">Todos</SelectItem>
                        {employees.map(e => <SelectItem key={e.id} value={e.id.toString()}>{e.fullName}</SelectItem>)}
                      </SelectContent>
                    </Select>
                    <Input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} />
                    <Input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} />
                    <Button variant="outline" onClick={() => { setSelectedEmployee(undefined); setStartDate(""); setEndDate(""); }}>Limpiar</Button>
                  </div>
                  <div className="rounded-md border overflow-hidden">
                    <table className="w-full text-sm">
                      <thead className="bg-muted/50 border-b">
                        <tr className="text-left">
                          <th className="p-4">Empleado</th>
                          <th className="p-4">Fecha</th>
                          <th className="p-4">Tipo</th>
                          <th className="p-4">Horas</th>
                        </tr>
                      </thead>
                      <tbody>
                        {filteredLogs.map(log => (
                          <tr key={log.id} className="border-b last:border-0">
                            <td className="p-4">{log.user?.fullName}</td>
                            <td className="p-4">{format(new Date(log.date), 'dd/MM/yyyy')}</td>
                            <td className="p-4 capitalize">{log.type === 'work' ? 'Trabajo' : 'Ausencia'}</td>
                            <td className="p-4">{Math.floor(log.totalHours / 60)}h {log.totalHours % 60}m</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </CardContent>
             </Card>
          </TabsContent>
        </Tabs>
      </div>
    </Layout>
  );
}
